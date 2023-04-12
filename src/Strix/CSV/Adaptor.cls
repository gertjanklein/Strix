Include Strix

IncludeGenerator Strix

Class Strix.CSV.Adaptor [ Abstract, DependsOn = Strix.Generator.Utilities, PropertyClass = Strix.CSV.PropertyParm ]
{

/// Which load method the parser should use: the one which expects
/// data indexed by column header ("header"), or by column index ("index").
Parameter PreferredLoader [ Constraint = "header,index", Flags = ENUM ] = "index";

// -----

/// For boolean properties: "true" values
Parameter True = "1,yes,true";

/// For boolean properties: "false" values
Parameter False = "0,no,false";

/// Expression to use to convert dates to logical format.
/// The value from the CSV file is present in variable "v".
Parameter DateExpression = "$ZDateH(v,3)";

/// Expression to use to convert times to logical format.
/// The value from the CSV file is present in variable "v".
Parameter TimeExpression = "$ZTimeH(v,1)";

/// Expression to use to convert numeric (floating point) values
/// to logical format. The value from the CSV file is present in
/// variable "v".
Parameter NumericExpression = "+v";

// =====

/// Loads the object from the data in Data (indexed by column header).
Method LoadByHeader(ByRef Data As %String) As %Status [ CodeMode = objectgenerator ]
{
	Set key = ""
	For  {
		#dim pd As %Dictionary.CompiledProperty
		Set pd = %compiledclass.Properties.GetNext(.key)
		If key = "" Quit
		
		Set Header = pd.Parameters.GetAt("CsvColumnHeader")
		If Header = "" Continue
		
		Set Name = pd.Name, Type = $$$DenormalizeClassname(pd.Type)
		
		Set Code = "v"
		If Type = "%Boolean" {
			Set Trues = $ListFromString(%parameter("True"))
			Set Falses = $ListFromString(%parameter("False"))
			Set Code = "$Case(v"
			For i = 1:1:$ListLength(Trues) Set Code = Code_","""_$List(Trues, i)_""":1"
			For i = 1:1:$ListLength(Falses) Set Code = Code_","""_$List(Falses, i)_""":0"
			Set Code = Code_",:v)"
			
		} ElseIf Type = "%Date" {
			Set Code = %parameter("DateExpression")
			
		} ElseIf Type = "%Time" {
			Set Code = %parameter("TimeExpression")
			
		} ElseIf $lf($lfs("%Numeric,%Float,%Double"), Type) {
			Set Code = %parameter("NumericExpression")
			
		}
		
		Set Code = "Set v = Data("""_Header_""") If v '= """" Set .."_Name_" = "_Code
		Do %code.WriteLine($Char(9)_Code)
	}
	
	; If a non-abstract fixup method is present, call it.
	If ##class(Strix.Generator.Utilities).HasConcreteMethod(%compiledclass, "PostProcessCsv") {
		Do %code.WriteLine($Char(9)_"Set sc = ..PostProcessCsv(.Data)")
		Do %code.WriteLine($Char(9)_"If 'sc Quit sc")
	}
	
	Do %code.WriteLine($Char(9)_"Quit $$$OK")
	
	Quit $$$OK
}

/// Loads the object from the data in Data (indexed by column number).
Method LoadByIndex(ByRef Data As %String) As %Status [ CodeMode = objectgenerator ]
{
	Set key = ""
	For  {
		#dim pd As %Dictionary.CompiledProperty
		Set pd = %compiledclass.Properties.GetNext(.key)
		If key = "" Quit
		
		Set Index = pd.Parameters.GetAt("CsvColumnNr")
		If Index = "" Continue
		
		Set Name = pd.Name, Type = $$$DenormalizeClassname(pd.Type)
		
		Set Code = "v"
		If Type = "%Boolean" {
			Set Trues = $ListFromString(%parameter("True"))
			Set Falses = $ListFromString(%parameter("False"))
			Set Code = "$Case(v"
			For i = 1:1:$ListLength(Trues) Set Code = Code_","""_$List(Trues, i)_""":1"
			For i = 1:1:$ListLength(Falses) Set Code = Code_","""_$List(Falses, i)_""":0"
			Set Code = Code_",:v)"
			
		} ElseIf Type = "%Date" {
			Set Code = %parameter("DateExpression")
			
		} ElseIf Type = "%Time" {
			Set Code = %parameter("TimeExpression")
			
		} ElseIf $lf($lfs("%Numeric,%Float,%Double"), Type) {
			Set Code = %parameter("NumericExpression")
			
		}
		
		Set Code = "Set v = Data("_Index_") If v '= """" Set .."_Name_" = "_Code
		Do %code.WriteLine($Char(9)_Code)
	}
	
	; If a non-abstract fixup method is present, call it.
	If ##class(Strix.Generator.Utilities).HasConcreteMethod(%compiledclass, "PostProcessCsv") {
		Do %code.WriteLine($Char(9)_"Set sc = ..PostProcessCsv(.Data)")
		Do %code.WriteLine($Char(9)_"If 'sc Quit sc")
	}
	
	Do %code.WriteLine($Char(9)_"Quit $$$OK")
	
	Quit $$$OK
}

/// This method is called after the object receives the data.
/// Datatype conversions have been run. The original data is
/// present in the Data array.
Method PostProcessCsv(ByRef Data As %String) As %Status [ Abstract ]
{
	Set Skip = 0
	Quit $$$OK
}

/// Compares the column headers present in Columns with the specifications
/// in the properties of this class. Returns comma-separated lists of:
/// - Missing: headers defined in a property but not in the Columns array
/// - Unused: headers in the Columns array for which no property is defined
/// The return value is true if all property-defined headers are present,
/// false otherwise.
ClassMethod CheckCSVColumns(ByRef Columns As %String, Output Missing As %String, Output Unused As %String) As %Boolean [ CodeMode = objectgenerator ]
{
	If %class.Name = "Strix.CSV.Adaptor" Quit $$$OK
	
	Do %code.WriteLine($Char(9)_"Set (Missing, Unused) = """"")
	Do %code.WriteLine($Char(9)_"Merge Test = Columns")
	Set key = ""
	For  {
		#dim pd As %Dictionary.CompiledProperty
		Set pd = %compiledclass.Properties.GetNext(.key)
		If key = "" Quit
		
		Set Header = pd.Parameters.GetAt("CsvColumnHeader")
		If Header = "" Continue
		If $Data(Headers(Header)) Continue
		Set Headers(Header) = ""
		
		Do %code.WriteLine($Char(9)_"Set v = """_Header_""" If $Data(Columns(v)) { Kill Test(v) } Else { Set Missing = Missing_$lb(v) }")
	}
	
	Do %code.WriteLine($Char(9)_"If Missing '= """" Set Missing = $ListToString(Missing)")
	
	Do %code.WriteLine($Char(9)_"Set v = """" For  { Set v=$Order(Test(v)) Quit:v=""""  Set Unused=Unused_$lb(v) }")
	Do %code.WriteLine($Char(9)_"If Unused '= """" Set Unused = $ListToString(Unused)")
	
	Do %code.WriteLine($Char(9)_"Quit Missing = """"")
	
	Quit $$$OK
}

}

