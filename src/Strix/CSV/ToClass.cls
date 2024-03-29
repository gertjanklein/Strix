Include Strix

Class Strix.CSV.ToClass Extends %RegisteredObject
{

/// Data to deduce class from. Must include header row.
Property Data As %Stream.Object;

/// Number of lines to skip before reading header line
Property SkipCount As %Integer [ InitialExpression = 0 ];

/// The separator to use in parsing the CSV data
Property Separator As %String [ InitialExpression = "," ];

/// Name of the class to create
Property ClassName As %String;

/// Superclass(es) for the class to create
Property SuperClass As %String [ InitialExpression = "%RegisteredObject,Strix.CSV.Adaptor" ];

/// Name of the property parameter for storing the column header.
/// If empty, this property parameter will not be generated.
Property CsvNameParameter As %String [ InitialExpression = "CsvColumnHeader" ];

/// Name of the property parameter for storing the column number.
/// If empty, this property parameter will not be generated.
Property CsvIndexParameter As %String [ InitialExpression = "CsvColumnNr" ];

/// When an existing class is regenerated, an attempt is made to keep
/// existing property types and parameters. If ResetClass is true,
/// all existing properties will be regenerated with their default
/// settings. Additionally, the storage for the class will be removed.
Property ResetClass As %Boolean [ InitialExpression = 0 ];

// =====

/// Create a class ClassName that can be used to hold a record
/// in the CSV in file FileName.
ClassMethod CreateFromFile(FileName As %String, ClassName As %String, Separator As %String) As %Status
{
	Set Me = ..%New(.ClassName, .Separator)
	Set Me.Data = ##class(%FileCharacterStream).%New()
	Set Status = Me.Data.LinkToFile(FileName)
	If 'Status Quit $$$BuildStatus("Error linking to file '{}':", Status, FileName)
	Set Status = Me.Create()
	If 'Status Quit Status
	Quit $$$OK
}

// =====

Method Create() As %Status
{
	#dim Parser As Strix.CSV.Parser
	Set Status = ..GetParser(.Parser)
	If 'Status Quit Status
	
	; Check for duplicate column headers
	Set sc = ..CheckColumns(Parser)
	If 'sc Quit sc
	
	#dim ClassDef As %Dictionary.ClassDefinition
	Set ClassDef = ##class(Strix.Generator.Utilities).GetClassDef(..ClassName, .IsNew, .Status)
	If 'Status Quit $$$BuildStatus("Can't create/open class definition for '{}':", Status, ..ClassName)
	Set ClassDef.Super = ..SuperClass
	
	If ..ResetClass {
		; Clear storage
		Do ClassDef.Storages.Clear()
	} Else {
		; Get existing property definitions (if any) to take datatype etc. from
		Do ..GetExistingProperties(ClassDef, .ExistingProperties)
	}
	
	; Remove all existing properties from the class definition
	Set Status = ClassDef.Properties.Clear()
	If 'Status Quit $$$BuildStatus("Can't clear existing properties in '{}':", Status, ..ClassName)
	
	For ColumnNr = 1:1:Parser.Data {
		Set ColumnName = Parser.Data(ColumnNr)
		If ColumnName = "" Continue
		
		Set PropertyName = ..GetPropertyName(ColumnName)
		If '$ZName(PropertyName, 6) Return $$$BuildStatus("Can't determine valid property name for column '{}' (tried '{}').",, ColumnName, PropertyName)
		
		;Check for duplicate property names
		If $Increment(PropertyNames(PropertyName)) > 1 {
			Return $$$BuildStatus("Property {} (column {}) occurs more than once.", , PropertyName, ColumnName)
		}
		
		#dim PropDef As %Dictionary.PropertyDefinition
		Set PropDef = ##class(Strix.Generator.Utilities).GetInCollection(ClassDef.Properties, PropertyName, 1, .Status)
		If 'Status Return $$$BuildStatus("Can't create/open property definition for column '{}', property '{}':", Status, ColumnName, PropertyName)
		
		Set PropDef.SequenceNumber = ColumnNr
		
		#dim Existing As %Dictionary.PropertyDefinition
		Set ParmName = $Select(..CsvNameParameter '= "": ColumnName, 1: ColumnNr)
		If $Data(ExistingProperties(ParmName), Existing) {
			; Keep existing type and property parameters
			Set PropDef.Type = Existing.Type
			Set PropDef.Parameters = Existing.Parameters
		} Else {
			Set Status = ..DetermineDataType(ColumnNr, ColumnName, PropDef)
			If 'Status Return Status
		}
		
		; Set the custom property parameter(s) for CSV column name and/or index.
		If ..CsvNameParameter '= "" Do PropDef.Parameters.SetAt(ColumnName, ..CsvNameParameter)
		If ..CsvIndexParameter '= "" Do PropDef.Parameters.SetAt(ColumnNr, ..CsvIndexParameter)
	}
	
	Set Status = ClassDef.%Save()
	If 'Status Quit $$$BuildStatus("Error saving class definition:", Status)
	
	Quit $$$OK
}

/// Checks for duplicate column headers; if found, returns a %Status
/// error containing their names.
Method CheckColumns(Parser As Strix.CSV.Parser) As %Status
{
	Set Names = ""
	For ColumnNr = 1:1:Parser.Data {
		Set ColumnName = Parser.Data(ColumnNr)
		If ColumnName = "" Continue
		If $Increment(Names(ColumnName)) '= 2 Continue
		Set Names = Names_$lb(ColumnName)
	}
	
	Set DupCount = $ll(Names)
	If DupCount {
		Set Names = """"_$lts(Names, """, """)_""""
		Set Msg = $Select(DupCount>1: "Columns {} occur", 1: "Column {} occurs")_" more than once."
		Quit $$$BuildStatus(Msg, , Names)
	}
	
	Quit $$$OK
}

/// Sets up the parser and reads the column header line.
/// Can be overridden to skip lines etc.
Method GetParser(Output Parser As Strix.CSV.Parser) As %Status
{
	Set Parser = ##class(Strix.CSV.Parser).GetParser(..Data, ..Separator, ..SkipCount)
	If 'Parser.Next(.Status) Quit $$$BuildStatus("Can't read first row from input:", Status)
	If Parser.Data < 2 Quit $$$BuildStatus("Only one column found; is separator correct?")
	Quit $$$OK
}

Method DetermineDataType(ColumnNr As %Integer, ColumnName As %String, PropDef As %Dictionary.PropertyDefinition) As %Status
{
	Set PropDef.Type = "%String"
	Do PropDef.Parameters.SetAt("", "MAXLEN")
	Quit $$$OK
}

/// Derive a valid Caché property name from a column header.
Method GetPropertyName(ColumnName As %String) As %String
{
	If $ZName(ColumnName, 6) Quit ColumnName
	
	Set Name = ""
	For i = 1:1:$Length(ColumnName) {
		Set Char = $Extract(ColumnName, i)
		If " _.(/-" [ Char, $Extract(ColumnName, i+1) ? 1A {
			Set Name = Name_$ZConvert($Extract(ColumnName, i+1), "U")
			Set i = i+1
			Continue
		}
		
		If $ZName(Name_Char, 6) Set Name = Name_Char
	}
	
	Quit Name
}

/// Returns property definitions already present in the class, indexed
/// on column name
Method GetExistingProperties(ClassDef As %Dictionary.ClassDefinition, Output Existing)
{
	Set ParmName = $Select(..CsvNameParameter '= "": ..CsvNameParameter, 1: ..CsvIndexParameter)
	Set key = ""
	For  {
		#dim PropDef As %Dictionary.PropertyDefinition
		Set PropDef = ClassDef.Properties.GetNext(.key)
		If key = "" Quit
		
		Set Column = PropDef.Parameters.GetAt(ParmName)
		If Column = "" Continue
		
		Set Existing(Column) = PropDef
	}
	Quit $$$OK
}

/// Initializer
Method %OnNew(ClassName As %String, Separator As %String) As %Status
{
	If $Data(ClassName) Set ..ClassName = ClassName
	If $Data(Separator) Set ..Separator = Separator
	Quit $$$OK
}

}
