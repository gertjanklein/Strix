Include Strix

/// Support code for tests.
Class Strix.Testing.Support Extends %RegisteredObject
{

/// Creates a class with the specified name. If a class
/// by that name already exists, it is deleted.
ClassMethod CreateClass(ClassName As %String, Super As %String = "%Persistent", Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	;Kill existing extent (if any)
	Set Status = ..KillExtent(ClassName)
	If 'Status Quit Status
	
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ClassName) {
		Set Status = ##class(%Dictionary.ClassDefinition).%DeleteId(ClassName)
		If 'Status Quit $$$BuildErr("Error deleting test class '"_ClassName_"'", Status)
	}
	
	Set ClassDef = ##class(%Dictionary.ClassDefinition).%New(ClassName, 25)
	Set ClassDef.Super = Super
	
	Quit $$$OK
}

/// Adds or updates a class parameter with the given value
ClassMethod SetClassParameter(ClassDef As %Dictionary.ClassDefinition, Name As %String, Value As %String) As %Status
{
	#dim pd As %Dictionary.ParameterDefinition
	Set pd = ##class(Strix.Generator.Utilities).GetInCollection(ClassDef.Parameters, Name, 1, .Status)
	Set pd.Default = Value
	Quit Status
}

/// Returns the property definition for the property with Name in ClassDef,
/// or an empty string if no such property exists.
ClassMethod GetProperty(ClassDef As %Dictionary.ClassDefinition, Name As %String) As %Dictionary.PropertyDefinition
{
	Set Key = ""
	For  {
		Set PropDef = ClassDef.Properties.GetNext(.Key)
		If Key = "" Quit
		If PropDef.Name = Name Return PropDef
	}
	Quit ""
}

/// Returns a property attribute (e.g., required) for the given property
/// in the given class. If Compiled is true, the compiled property is checked.
/// If the property definition can't be opened, an error is returned in Status.
ClassMethod GetPropertyAttribute(ClassName As %String, PropertyName As %String, Attribute As %String, Compiled As %Boolean = 0, Output Status As %Status) As %String
{
	Set PropertyClass = $Select(Compiled: "%Dictionary.CompiledProperty", 1: "%Dictionary.PropertyDefinition")
	Set PropDef = $ZObjClassMethod(PropertyClass, "%OpenId", ClassName_"||"_PropertyName, .Status)
	If 'Status Quit ""
	Set Value = $ZObjProperty(PropDef, Attribute)
	Quit Value
}

/// Adds a new property to an existing class definition.
ClassMethod AddProperty(ClassDef As %Dictionary.ClassDefinition, Name As %String, Type As %String, Collection As %String = "") As %Dictionary.PropertyDefinition
{
	Set Property = ##class(%Dictionary.PropertyDefinition).%New()
	Set Property.Name = Name
	Set Property.Type = Type
	Set Property.Collection = Collection
	Do ClassDef.Properties.Insert(Property)
	Quit Property
}

/// Sets a property parameter value
ClassMethod SetPropertyParameter(ClassDef As %Dictionary.ClassDefinition, PropertyName As %String, ParameterName As %String, Value As %String = "", Compile As %Boolean = 1) As %Status
{
	; Find property definition
	
	Set Key = ""
	For  {
		Set PropDef = ClassDef.Properties.GetNext(.Key)
		If Key = "" Quit
		If PropDef.Name = PropertyName Quit
	}
	If Key = "" Quit $$$BuildStatus("No property '{} found.",, PropertyName)
	
	; Set parameter
	
	Do PropDef.Parameters.SetAt(Value, ParameterName)
	
	; Compile if so requested
	
	If Compile Quit ..SaveAndCompile(ClassDef)
	
	Quit $$$OK
}

/// Saves and compiles the class passed as a class definition.
ClassMethod SaveAndCompile(ClassDef As %Dictionary.ClassDefinition) As %Status
{
	Set Status = ClassDef.%Save()
	If 'Status Quit $$$BuildErr("Error saving class '"_ClassDef.Name_"'", Status)
	
	Set Status = $System.OBJ.Compile(ClassDef.Name, "cko0-d")
	If 'Status Quit $$$BuildErr("Error compiling class '"_ClassDef.Name_"'", Status)
	
	Quit $$$OK
}

/// Remove a class and any data it may contain.
ClassMethod RemoveClass(ClassName As %String) As %Status
{
	Set Status = ..KillExtent(ClassName)
	If 'Status Quit Status
	
	;Delete the class itself
	Set Status = $System.OBJ.Delete(ClassName, "-d")
	If 'Status Quit $$$BuildErr("Error deleting test class '"_ClassName_"'", Status)
	
	Quit $$$OK
}

/// Removes the extent for a class if it has one and is compiled.
ClassMethod KillExtent(ClassName As %String) As %Status
{
	;If %KillExtent doesn't exist or isn't runnable we're done
	If '##class(%Dictionary.CompiledMethod).%ExistsId(ClassName_"||%KillExtent") Quit $$$OK
	
	Set Status = $ZObjClassMethod(ClassName, "%KillExtent")
	If 'Status Quit $$$BuildErr("Error clearing extent for class '"_ClassName_"'", Status)
	
	Quit $$$OK
}

/// Parses an XData block passed in by id, an returns all objects in it
/// with the specified element/classname.
ClassMethod XDataToObjects(XDataId As %String, ElementName As %String = "", ClassName As %String, Objects As %ListOfObjects) As %Status
{
	If '$IsObject(Objects) Set Objects = ##class(%ListOfObjects).%New()
	If ElementName = "" Set ElementName = $Parameter(ClassName, "XMLTYPE")
	If ElementName = "" Set ElementName = $Piece(ClassName, ".", *)
	
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(XDataId,, .sc)
	If 'sc Quit $$$BuildStatus("Error opening XData '{}':", sc, XDataId)
	
	Set Reader = ##class(%XML.Reader).%New()
	Set sc = Reader.OpenStream(XData.Data)
	If 'sc Quit $$$BuildStatus("Error parsing XData '{}' as XML:", sc, XDataId)
	
	Do Reader.Correlate(ElementName, ClassName)
	While Reader.Next(.Object, .sc) {
		Do Objects.Insert(Object)
	}
	If 'sc Quit $$$BuildStatus("Error correlating object from XData '{}':", sc, XDataId)
	
	Quit $$$OK
}

/// Returns the contents of an XData block in a temporary stream.
/// XDataId is expected in the form [ClassName]||[XDataName]. If
/// parameter Strip is true, the first and last non-empy lines
/// are removed. This is so arbitrary content can be placed in the
/// XData block by wrapping it in an XML root element.
ClassMethod GetXData(XDataId As %String, Strip As %Boolean = 0, Output Status As %Status) As %Stream.Object
{
	Set Stream = ##class(%Stream.TmpCharacter).%New()
	
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(XDataId, , .Status)
	If 'Status Set Status = $$$BuildStatus("Error opening {}:", Status, XDataId) Quit ""
	
	If Strip {
		For LineNr = 1:1 {
			If XData.Data.AtEnd Quit
			
			Set Line = XData.Data.ReadLine()
			If LineNr = 1 Continue
			If XData.Data.AtEnd Quit
			
			Do Stream.WriteLine(Line)
		}
		
	} Else {
		Do Stream.CopyFrom(XData.Data)
		
	}
	
	Quit Stream
}

}
