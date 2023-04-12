/// Tests Strix.XML.ToClass.
Class Strix.Tests.SchemaReader Extends Strix.Testing.TestCase
{

Parameter TestPackage = "Strix.Tests.SchemaReader";

Property Reader As Strix.XML.SchemaReader;

Property CallbackObject As Strix.XML.SchemaReaderCallback;

/// Temporary data
Property ScratchData As %String [ MultiDimensional ];

// ===== Tests

/// Test processing an XSD passes in a stream (ProcessStream method).
Method TestProcessStream()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	If '..AssertClassExists("Base", "Base class generated.") Quit
	Do ..AssertHasProperty("Base", "Element1", "Base has Element1 property.")
	
	If '..AssertClassExists("Element1", "Element1 class generated.") Quit
	Do ..AssertHasProperty("Element1", "String1", "Element1 has String1 property.")
	Do ..AssertHasProperty("Element1", "String2", "Element1 has String2 property.")
	
	Quit
}

// -----

/// Tests that the basic callback method, ProcessParseTree, is
/// called during schema processing.
Method TestProcessParseTree()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "ProcessParseTree", "Callback1")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	Quit
}

Method Callback1(ClassTree As %String) As %Status
{
	If '..AssertNotEmpty(ClassTree, "We receive a class node as parameter.") Quit $$$OK
	Do ..AssertNotEmpty($Order(@ClassTree@("")), "The node contains data.")
	Quit $$$OK
}

// -----

/// Tests that the basic callback method, ProcessParseTree, can
/// abort schema processing by returning an error.
Method TestCallbackStatus()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "ProcessParseTree", "Callback2")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertErrorStatus(sc, "Processing schema fails.") Quit
	Do ..AssertStatusParameter(sc, 1, "Stop here.", "Proper error is returned.") Quit
	
	Quit
}

Method Callback2(ClassTree As %String) As %Status
{
	Quit $$$BuildStatus("Stop here.")
}

// -----

/// Tests that callback method HandleClass is called for each class.
Method TestProcessClassNode()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "ProcessClassNode", "Callback3")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	Do ..Assert($Data(..ScratchData("Base")), "Callback called for Base class.")
	Do ..Assert($Data(..ScratchData("Element1")), "Callback called for Element1 class.")
	
	Quit
}

Method Callback3(Name As %String) As %Status
{
	Set ShortName = $Piece(Name, ".", *)
	If '..Assert("Base,Element1" [ ShortName, "Name '{}' is expected.", ShortName) Quit
	Set ..ScratchData(ShortName) = ""
	Quit $$$OK
}

// -----

/// Tests that callback method HandleClass is called for each class.
Method TestHandleProperty()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "HandleProperty", "Callback4")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	Do ..Assert($Data(..ScratchData("Element1")), "Callback called for Element1 property.")
	Do ..Assert($Data(..ScratchData("String1")), "Callback called for String1 property.")
	Do ..Assert($Data(..ScratchData("String2")), "Callback called for String2 property.")
	
	Quit
}

Method Callback4(Name As %String, XmlName As %String, Type As %String, IsDataType As %Boolean) As %Status
{
	If '..Assert("Element1,String1,String2" [ Name, "Name '{}' is expected.", Name) Quit
	If Name = "Element1" {
		Do ..AssertEqual(Type, ..#TestPackage_".Element1", "Property Element1 has proper class.")
		Do ..AssertFalse(IsDataType, "Property {} type is not datatype.", Name)
	} Else {
		Do ..AssertEqual(Type, "%String", "Property {} has proper class.", Name)
		Do ..AssertTrue(IsDataType, "Property {} type is datatype.", Name)
	}
	Set ..ScratchData(Name) = ""
	Quit $$$OK
}

// -----

/// Tests renaming a class.
Method TestRenameClass()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "HandleClass", "Callback5")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	Do ..AssertClassNotExists("Base", "No Base class present (should be renamed).")
	If ..AssertClassExists("BaseRenamed", "Base class renamed to BaseRenamed.") Quit
	Do ..AssertHasProperty("BaseRenamed", "Element1", "BaseRenamed has Element1 property.")
	
	If '..AssertClassExists("Element1", "Element1 class generated.") Quit
	Do ..AssertHasProperty("Element1", "String1", "Element1 has String1 property.")
	Do ..AssertHasProperty("Element1", "String2", "Element1 has String2 property.")
	
	Quit
}

Method Callback5(Name As %String, XmlName As %String) As %Status
{
	If $$$ClassShortName(Name) '= "Base" Quit $$$OK
	Set sc = ..CallbackObject.RenameClass("BaseRenamed")
	Do ..AssertStatusOk(sc, "Changing class name does not return an error.")
	Quit $$$OK
}

// -----

/// Tests renaming a property.
Method TestRenameProperty()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	Set sc = ..BuildCallBack(Reader, "HandleProperty", "Callback6")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	If '..AssertClassExists("Base", "Base class generated.") Quit
	Do ..AssertHasProperty("Base", "Element", "Base has Element property.")
	
	If '..AssertClassExists("Element1", "Element1 class generated.") Quit
	Do ..AssertHasProperty("Element1", "String1", "Element1 has String1 property.")
	Do ..AssertHasProperty("Element1", "SecondString", "Element1 has SecondString property.")
	
	Quit
}

Method Callback6(Name As %String, XmlName As %String, Type As %String, IsDataType As %Boolean) As %Status
{
	If Name = "Element1" {
		Set sc = ..CallbackObject.RenameProperty("Element")
		Do ..AssertStatusOk(sc, "Changing property name does not return an error.")
	} ElseIf Name = "String2" {
		Set sc = ..CallbackObject.RenameProperty("SecondString")
		Do ..AssertStatusOk(sc, "Changing property name does not return an error.")
	}
	Quit $$$OK
}

// -----

/// Tests setting a property's required attribute.
Method TestChangeRequired()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	
	Set sc = ..BuildCallBack(Reader, "HandleProperty", "Callback7")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	Do ..AssertPropertyRequired("Element1", "String1", 1, "String1 property is now required.")
	Do ..AssertPropertyRequired("Element1", "String2", 0, "String2 is no longer required.")
	
	Quit
}

Method Callback7(Name As %String, XmlName As %String, Type As %String, IsDataType As %Boolean) As %Status
{
	If Name = "String1" {
		Set sc = ..CallbackObject.SetPropertyRequired(1)
		Do ..AssertStatusOk(sc, "Changing property required flag does not return an error.")
	} ElseIf Name = "String2" {
		Set sc = ..CallbackObject.SetPropertyRequired(0)
		Do ..AssertStatusOk(sc, "Changing property required flag does not return an error.")
	}
	Quit $$$OK
}

// -----

/// Tests setting a class parameter.
Method TestSetClassParameter()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	
	Set sc = ..BuildCallBack(Reader, "HandleClass", "Callback8")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	;Check parameter
	Set Value = $$$GetClassParameter(..#TestPackage_".Base", "XMLIGNORENULL")
	Do ..AssertEqual(Value, "inputonly", "Class parameter set.")
	
	Quit
}

Method Callback8(Name As %String, XmlName As %String) As %Status
{
	If $$$ClassShortName(Name) '= "Base" Quit $$$OK
	Set sc = ..CallbackObject.SetClassParameter("XMLIGNORENULL", "inputonly")
	Do ..AssertStatusOk(sc, "Setting class parameter does not return an error.")
	Quit $$$OK
}

// -----

/// Tests setting a property parameter.
Method TestSetPropertyParameter()
{
	#dim Reader As Strix.XML.SchemaReader
	Set Reader = ..GetReader()
	Set XSDStream = ..GetXSD("Schema1")
	
	Set sc = ..BuildCallBack(Reader, "HandleProperty", "Callback9")
	If '..AssertStatusOk(sc, "Building callback class works.") Quit
	
	Set sc = Reader.ProcessStream(XSDStream, ..#TestPackage)
	If '..AssertStatusOk(sc, "Processing schema works.") Quit
	
	;Check parameter
	Set Value = $$$GetPropertyParameter(..#TestPackage_".Element1", "String1", "MAXLEN")
	Do ..AssertEqual(Value, 5, "Property parameter set.")
	
	Quit
}

Method Callback9(Name As %String, XmlName As %String, Type As %String, IsDataType As %Boolean) As %Status
{
	If Name '= "String1" Quit $$$OK
	Set sc = ..CallbackObject.SetPropertyParameter("MAXLEN", 5)
	Do ..AssertStatusOk(sc, "Setting class parameter does not return an error.")
	Quit $$$OK
}

// ===== Helpers

Method GetReader() As Strix.XML.SchemaReader
{
	Set Reader = ##class(Strix.XML.SchemaReader).%New()
	Set Reader.CompileClasses = 0
	Set Reader.MakePersistent = 0
	Set Reader.MakeSerial = 0
	Quit Reader
}

Method GetXSD(Name As %String, Output Status As %Status) As %Stream.Object
{
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(..%ClassName(1)_"||"_Name, , .Status)
	Quit XData.Data
}

Method AssertClassExists(Name As %String, Description As %String, Parameters... As %String) As %Boolean
{
	If Name '[ "." Set Name = ..#TestPackage_"."_Name
	Quit ..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(Name), .Description, .Parameters)
}

Method AssertClassNotExists(Name As %String, Description As %String, Parameters... As %String) As %Boolean
{
	If Name '[ "." Set Name = ..#TestPackage_"."_Name
	Quit ..Assert('##class(%Dictionary.ClassDefinition).%ExistsId(Name), .Description, .Parameters)
}

Method AssertHasProperty(ClassName As %String, PropertyName As %String, Description As %String, Parameters... As %String) As %Boolean
{
	If ClassName '[ "." Set ClassName = ..#TestPackage_"."_ClassName
	Quit ..Assert(##class(%Dictionary.PropertyDefinition).%ExistsId(ClassName_"||"_PropertyName), .Description, .Parameters)
}

Method AssertPropertyRequired(ClassName As %String, PropertyName As %String, Value As %Boolean, Description As %String, Parameters... As %String) As %Boolean
{
	If ClassName '[ "." Set ClassName = ..#TestPackage_"."_ClassName
	Set Required = ##class(Strix.Testing.Support).GetPropertyAttribute(ClassName, PropertyName, "Required")
	Quit ..AssertEqual(Required, Value, .Description, .Parameters)
}

Method BuildCallBack(Reader As Strix.XML.SchemaReader, Override As %String, With As %String) As %Status
{
	Set ClassName = ..#TestPackage_".CallbackHandler"
	Set sc = ##class(Strix.Testing.Support).CreateClass(ClassName, "Strix.XML.SchemaReaderCallback", .Dic)
	If 'sc Quit $$$BuildStatus("Error creating callback handler:", sc)
	
	Set md = ##class(%Dictionary.MethodDefinition).%OpenId("Strix.XML.SchemaReaderCallback||"_Override,, .sc)
	If 'sc Quit $$$BuildStatus("Error opening original callback method ({}) to override:", sc, Override)
	Set md = md.%ConstructClone()
	Do md.Implementation.Clear()
	
	Set Parms = ""
	For i = 1:1:$Length(md.FormalSpec, ",") {
		Set Name = $Piece($Piece(md.FormalSpec, ",", i), ":")
		If "*&" [ Name Set Name = $Extract(Name, 2, *)
		If i > 1 Set Parms = Parms_","
		Set Parms = Parms_"."_Name
	}
	
	Set Line = " Set sc=%zCurrentTestCase."_With_"("_Parms_")"
	Do md.Implementation.WriteLine(Line)
	Do md.Implementation.WriteLine(" If 'sc Quit sc")
	Do md.Implementation.WriteLine(" Quit ##super("_Parms_")")
	Do Dic.Methods.Insert(md)
	
	Set sc = Dic.%Save()
	If 'sc Quit $$$BuildStatus("Error saving callback {}:", sc, ClassName)
	
	Set sc = $System.OBJ.Compile(ClassName, "-dk")
	If 'sc Quit $$$BuildStatus("Error compiling callback {}:", sc, ClassName)
	
	; Create callback instance
	Set Callback = $ZObjClassMethod(ClassName, "%New")
	
	;Make reader know about callback and v.v.
	Set Reader.Callback = Callback
	
	Set ..Reader = Reader
	Set ..CallbackObject = Callback
	
	Quit $$$OK
}

// ===== Setup/teardown

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	Set %zCurrentTestCase = $this
	Quit $$$OK
}

/// Delete generated classes after each test
Method OnAfterTest(Name As %String) As %Status
{
	Set sc = $System.OBJ.DeletePackage(..#TestPackage, "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test package {}:", sc, ..#TestPackage)
	Kill ..ScratchData
	Quit $$$OK
}

/// Final cleanup, if necessary
Method TearDown(FailedTests As %String) As %Status
{
	Kill %zCurrentTestCase
	Set sc = $System.OBJ.DeletePackage(..#TestPackage, "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test package {}:", sc, ..#TestPackage)
	Quit $$$OK
}

// ===== Data

XData Schema1
{
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema'>
<xs:element name='Base'>
<xs:complexType>
<xs:choice maxOccurs='1'>
<xs:element name='Element1'>
<xs:complexType>
<xs:sequence>
<xs:element name='String1' type='xs:string' minOccurs='0'/>
<xs:element name='String2' type='xs:string' minOccurs='1'/>
</xs:sequence>
</xs:complexType>
</xs:element>
</xs:choice>
</xs:complexType>
</xs:element>
</xs:schema>
}

}
