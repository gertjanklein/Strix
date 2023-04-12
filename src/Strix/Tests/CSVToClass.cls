/// Tests Strix.CSV.Parser.
Class Strix.Tests.CSVToClass Extends (Strix.Testing.TestCase, Strix.CSV.ToClass) [ Inheritance = left ]
{

Parameter TestClassName = "Strix.Tests.Temp.CSVAdaptorTest";

/// Name of file to use as input
Property TestFileName As %String;

/// Stream to use as input to parser
Property Stream As %Stream.Object;

// ===== Tests

/// Test basic functionality
Method TestBasic()
{
	#dim p As Strix.CSV.ToClass
	Set p = ..MakeProcessor("a,b,c", "1,2,3")
	
	Set sc = p.Create()
	If '..AssertStatusOk(sc, "Test class is created without error.") Quit
	If '..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(..#TestClassName), "Test class exists.") Quit
	If '..AssertStatusOk($System.OBJ.Compile(..#TestClassName, "k-d"), "Test class compiles ok.") Quit
	
	Set cd = ##class(%Dictionary.ClassDefinition).%OpenId(..#TestClassName)
	Do ..AssertEqual(cd.Super, "%RegisteredObject,Strix.CSV.Adaptor", "Test class has proper superclasses")
	
	#dim pd As %Dictionary.PropertyDefinition
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "a")
	If ..AssertNotEmpty(pd, "Property a exists.") {
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnNr"), "1", "CsvColumn for property a is correct.")
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnHeader"), "a", "CsvColumnHeader for property a is correct.")
	}
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "b")
	If ..AssertNotEmpty(pd, "Property b exists.") {
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnNr"), "2", "CsvColumn for property b is correct.")
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnHeader"), "b", "CsvColumnHeader for property b is correct.")
	}
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "c")
	If ..AssertNotEmpty(pd, "Property c exists.") {
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnNr"), "3", "CsvColumn for property c is correct.")
		Do ..AssertEqual(pd.Parameters.GetAt("CsvColumnHeader"), "c", "CsvColumnHeader for property c is correct.")
	}
	
	Do ..Stream.Rewind()
	
	#dim Parser As Strix.CSV.Parser
	Set Parser = ##class(Strix.CSV.Parser).GetParser(..Stream, ",", 1)
	Set Parser.AdaptorClassName = ..#TestClassName
	If ..Assert(Parser.Next(.sc), "Parser can get record.") {
		Set o = Parser.GetObject()
		If '..Assert($IsObject(o), "An object is returned for the record.") Quit
		Do ..AssertEqual(o.a, "1", "Property a has correct value.")
		Do ..AssertEqual(o.b, "2", "Property b has correct value.")
		Do ..AssertEqual(o.c, "3", "Property c has correct value.")
	}
	
	Quit
}

/// Test basic functionality
Method TestCreateForFile()
{
	Set sc = ..MakeProcessorForFile("a,b,c", "1,2,3")
	If '..AssertStatusOk(sc, "Created processor.") Quit
	
	If '..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(..#TestClassName), "Test class exists.") Quit
	If '..AssertStatusOk($System.OBJ.Compile(..#TestClassName, "k-d"), "Test class compiles ok.") Quit
	
	Set cd = ##class(%Dictionary.ClassDefinition).%OpenId(..#TestClassName)
	Do ..AssertEqual(cd.Super, "%RegisteredObject,Strix.CSV.Adaptor", "Test class has proper superclasses")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "a")
	Do ..AssertNotEmpty(pd, "Property a exists.")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "b")
	Do ..AssertNotEmpty(pd, "Property b exists.")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "c")
	Do ..AssertNotEmpty(pd, "Property c exists.")
	
	Quit
}

/// Tests DetermineDataType can be overridden
Method TestChangeDatatype()
{
	Set p = ..MakeProcessor("String,Date,Integer", "1,2,3")
	
	Set sc = p.Create()
	If '..AssertStatusOk(sc, "Test class is created without error.") Quit
	If '..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(..#TestClassName), "Test class exists.") Quit
	If '..AssertStatusOk($System.OBJ.Compile(..#TestClassName, "k-d"), "Test class compiles ok.") Quit
	
	Set cd = ##class(%Dictionary.ClassDefinition).%OpenId(..#TestClassName)
	Do ..AssertEqual(cd.Super, "%RegisteredObject,Strix.CSV.Adaptor", "Test class has proper superclasses")
	
	#dim pd As %Dictionary.PropertyDefinition
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "String")
	Do ..AssertEqual(pd.Type, "%String", "Property String type is %String")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "Date")
	Do ..AssertEqual(pd.Type, "%Date", "Property Date type is %Date")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "Integer")
	Do ..AssertEqual(pd.Type, "%Integer", "Property Integer type is %Integer")
	
	Quit
}

/// Tests GetParser can be overridden
Method TestGetParser()
{
	Set p = ..MakeProcessor("x,y,z", "a,b,c", "1,2,3")
	
	Set sc = p.Create()
	If '..AssertStatusOk(sc, "Test class is created without error.") Quit
	If '..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(..#TestClassName), "Test class exists.") Quit
	If '..AssertStatusOk($System.OBJ.Compile(..#TestClassName, "k-d"), "Test class compiles ok.") Quit
	
	Set cd = ##class(%Dictionary.ClassDefinition).%OpenId(..#TestClassName)
	Do ..AssertEqual(cd.Super, "%RegisteredObject,Strix.CSV.Adaptor", "Test class has proper superclasses")
	
	#dim pd As %Dictionary.PropertyDefinition
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "a")
	Do ..AssertNotEmpty(pd, "Property a exists.")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "b")
	Do ..AssertNotEmpty(pd, "Property b exists.")
	
	Set pd = ##class(Strix.Testing.Support).GetProperty(cd, "c")
	Do ..AssertNotEmpty(pd, "Property c exists.")
	
	Quit
}

// =====

/// Overridden method from Strix.CSV.ToClass
Method DetermineDataType(ColumnNr As %Integer, ColumnName As %String, PropDef As %Dictionary.PropertyDefinition) As %Status
{
	If ..Runner.CurrentTestMethod = "TestChangeDatatype" {
		If ColumnName = "String" {
			Set PropDef.Type = "%String"
			Do PropDef.Parameters.SetAt("", "MAXLEN")
		} ElseIf ColumnName = "Date" {
			Set PropDef.Type = "%Date"
		} ElseIf ColumnName = "Integer" {
			Set PropDef.Type = "%Integer"
		}
		Quit $$$OK
	}
	Quit ##super(ColumnNr, ColumnName, PropDef)
}

/// Overridden method from Strix.CSV.ToClass
Method GetParser(Output Parser As Strix.CSV.Parser) As %Status
{
	If ..Runner.CurrentTestMethod = "TestGetParser" {
		Set Parser = ##class(Strix.CSV.Parser).GetParser(..Data, ..Separator, 1)
		If 'Parser.Next(.Status) Quit $$$BuildStatus("Can't read first row from input:", Status)
		If Parser.Data < 2 Quit $$$BuildStatus("Only one column found; is separator correct?")
		Quit $$$OK
	}
	Quit ##super(.Parser)
}

// ===== Helpers.

Method MakeProcessorForFile(Lines... As %String)
{
	Set ..TestFileName = ##class(%File).TempFilename("csv")
	Set File = ##class(%Stream.FileCharacter).%New()
	Set Status = File.LinkToFile(..TestFileName)
	If 'Status Set Status = $$$BuildStatus("Error linking to file '{}'", sc, FileName) Quit ""
	
	For i = 1:1:$Get(Lines) Do File.WriteLine(Lines(i))
	
	Set Status = File.%Save()
	If 'Status Set Status = $$$BuildStatus("Error saving file '{}'", Status, ..TestFileName) Quit ""
	
	Set Status = ##class(Strix.CSV.ToClass).CreateFromFile(..TestFileName, ..#TestClassName, ",")
	
	Quit Status
}

Method MakeProcessor(Lines... As %String)
{
	Set Processor = $this
	Set Processor.Separator = ","
	Do ..MakeStream(Lines...)
	Set Processor.Data = ..Stream
	Set Processor.ClassName = ..#TestClassName
	Quit Processor
}

Method MakeStream(Lines... As %String)
{
	Set ..Stream = ##class(%Stream.TmpCharacter).%New()
	Do ..Stream.Clear()
	For i = 1:1:$Get(Lines) {
		Do ..Stream.WriteLine($Get(Lines(i)))
	}
	Do ..Stream.Rewind()
}

// ===== Cleanup code.

/// Code to run after all tests in this class have been executed.
Method TearDown(FailedTests As %String) As %Status
{
	If FailedTests '= "" Quit $$$OK
	Set sc = ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	If 'sc Quit sc
	Do ##class(%File).Delete(..TestFileName)
	Quit $$$OK
}

}
