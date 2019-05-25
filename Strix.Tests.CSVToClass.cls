<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.CSVToClass">
<Description>
Tests Strix.CSV.Parser.</Description>
<Super>Strix.Testing.TestCase,Strix.CSV.ToClass</Super>
<TimeCreated>64594,31293.265299</TimeCreated>
<Inheritance>left</Inheritance>

<Parameter name="TestClassName">
<Default>Strix.Tests.Temp.CSVAdaptorTest</Default>
</Parameter>

<Property name="TestFileName">
<Description>
Name of file to use as input</Description>
<Type>%String</Type>
</Property>

<Property name="Stream">
<Description>
Stream to use as input to parser</Description>
<Type>%Stream.Object</Type>
</Property>

<UDLText name="T">
<Content><![CDATA[
// ===== Tests

]]></Content>
</UDLText>

<Method name="TestBasic">
<Description>
Test basic functionality</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestCreateForFile">
<Description>
Test basic functionality</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestChangeDatatype">
<Description>
Tests DetermineDataType can be overridden</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestGetParser">
<Description>
Tests GetParser can be overridden</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="DetermineDataType">
<Description>
Overridden method from Strix.CSV.ToClass</Description>
<FormalSpec>ColumnNr:%Integer,ColumnName:%String,PropDef:%Dictionary.PropertyDefinition</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="GetParser">
<Description>
Overridden method from Strix.CSV.ToClass</Description>
<FormalSpec>*Parser:Strix.CSV.Parser</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	If ..Runner.CurrentTestMethod = "TestGetParser" {
		Set Parser = ##class(Strix.CSV.Parser).GetParser(..Data, ..Separator, 1)
		If 'Parser.Next(.Status) Quit $$$BuildStatus("Can't read first row from input:", Status)
		If Parser.Data < 2 Quit $$$BuildStatus("Only one column found; is separator correct?")
		Quit $$$OK
	}
	Quit ##super(.Parser)
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Helpers.

]]></Content>
</UDLText>

<Method name="MakeProcessorForFile">
<FormalSpec>Lines...:%String</FormalSpec>
<Implementation><![CDATA[
	Set ..TestFileName = ##class(%File).TempFilename("csv")
	Set File = ##class(%Stream.FileCharacter).%New()
	Set Status = File.LinkToFile(..TestFileName)
	If 'Status Set Status = $$$BuildStatus("Error linking to file '{}'", sc, FileName) Quit ""
	
	For i = 1:1:$Get(Lines) Do File.WriteLine(Lines(i))
	
	Set Status = File.%Save()
	If 'Status Set Status = $$$BuildStatus("Error saving file '{}'", Status, ..TestFileName) Quit ""
	
	Set Status = ##class(Strix.CSV.ToClass).CreateFromFile(..TestFileName, ..#TestClassName, ",")
	
	Quit Status
]]></Implementation>
</Method>

<Method name="MakeProcessor">
<FormalSpec>Lines...:%String</FormalSpec>
<Implementation><![CDATA[
	Set Processor = $this
	Set Processor.Separator = ","
	Do ..MakeStream(Lines...)
	Set Processor.Data = ..Stream
	Set Processor.ClassName = ..#TestClassName
	Quit Processor
]]></Implementation>
</Method>

<Method name="MakeStream">
<FormalSpec>Lines...:%String</FormalSpec>
<Implementation><![CDATA[
	Set ..Stream = ##class(%Stream.TmpCharacter).%New()
	Do ..Stream.Clear()
	For i = 1:1:$Get(Lines) {
		Do ..Stream.WriteLine($Get(Lines(i)))
	}
	Do ..Stream.Rewind()
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Cleanup code.

]]></Content>
</UDLText>

<Method name="TearDown">
<Description>
Code to run after all tests in this class have been executed.</Description>
<FormalSpec>FailedTests:%String</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	If FailedTests '= "" Quit $$$OK
	Set sc = ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	If 'sc Quit sc
	Do ##class(%File).Delete(..TestFileName)
	Quit $$$OK
]]></Implementation>
</Method>
</Class>
</Export>
