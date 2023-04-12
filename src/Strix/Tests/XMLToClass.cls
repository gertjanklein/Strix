/// Tests Strix.XML.ToClass.
Class Strix.Tests.XMLToClass Extends Strix.Testing.TestCase
{

/// Base package for created test classes
Parameter TestClassPackage = "TestXMLToClass";

// =====

/// Names of temporary files, to be cleaned up
Property TempFiles As list Of %String(MAXLEN = 512);

// ===== Tests

/// Test creating simple test class with one property
Method TestBasic()
{
	Set Xml = "<a><b>x</b></a>"
	
	Set FileName = ..TempFile(Xml)
	
	Set Status = ##class(Strix.XML.ToClass).Create(FileName, ..#TestClassPackage, .ClassName)
	If '..AssertStatusOk(Status, "Create class from XML") Quit
	If '..AssertEqual(ClassName, ..#TestClassPackage_".a", "Class should have expected name.") Quit
	If '..AssertTrue(..ClassExists(ClassName), "Generated class should exist.") Quit
	
	Set PropExists = ..HasProperty(ClassName_"||b", .Type, .Collection, .Parameters)
	If ..AssertTrue(PropExists, "Property b should exist.") {
		Do ..AssertEqual(Type, "%String", "Property b should be of type %String.")
		Do ..AssertEqual(Collection, "", "Property b should have no collection.")
	}
	
	;Check if parsed object outputs the same Xml.
	Do ..CheckRoundTrip(ClassName, Xml)
	
	Do $System.OBJ.Delete(ClassName, "-d")
	
	Quit
}

/// Test creating simple test class with one property of type list
Method TestBasicListProp()
{
	Set Xml = "<a><b>x</b><b></b></a>"
	
	Set FileName = ..TempFile(Xml)
	
	Set Status = ##class(Strix.XML.ToClass).Create(FileName, ..#TestClassPackage, .ClassName)
	If '..AssertStatusOk(Status, "Create class from XML") Quit
	If '..AssertEqual(ClassName, ..#TestClassPackage_".a", "Class should have expected name.") Quit
	If '..AssertTrue(..ClassExists(ClassName), "Generated class should exist.") Quit
	
	Set PropExists = ..HasProperty(ClassName_"||b", .Type, .Collection, .Parameters)
	If ..AssertTrue(PropExists, "Property b should exist.") {
		Do ..AssertEqual(Type, "%String", "Property b should be of type %String.")
		Do ..AssertEqual(Collection, "list", "Property b should have collection list.")
	}
	
	;Check if parsed object outputs the same Xml.
	Do ..CheckRoundTrip(ClassName, Xml)
	
	Do $System.OBJ.Delete(ClassName, "-d")
	
	Quit
}

/// Test creating simple test class with one property with just
/// an attribute but no subelements: should create a class with
/// a "content" property.
Method TestPropWithAttr()
{
	Set Xml = "<a><b id=""2"">x</b><b></b></a>"
	
	Set FileName = ..TempFile(Xml)
	
	Set Status = ##class(Strix.XML.ToClass).Create(FileName, ..#TestClassPackage, .ClassName)
	If '..AssertStatusOk(Status, "Create class from XML") Quit
	If '..AssertEqual(ClassName, ..#TestClassPackage_".a", "Class should have expected name.") Quit
	If '..AssertTrue(..ClassExists(ClassName), "Generated class should exist.") Quit
	
	;Property b should be of type <package>.b
	Set Classname2 = ..#TestClassPackage_".b"
	
	;Check a.b
	Set PropExists = ..HasProperty(ClassName_"||b", .Type, .Collection, .Parameters)
	If ..AssertTrue(PropExists, "Property b should exist.") {
		Do ..AssertEqual(Type, Classname2, "Property b should be a subclass.")
		Do ..AssertEqual(Collection, "list", "Property b should have collection list.")
		Do ..AssertEqual($Get(Parameters("XMLPROJECTION")), "ELEMENT", "Property b should have proper XMLPROJECTION.")
	}
	
	;Check a.b.id
	Set PropExists = ..HasProperty(Classname2_"||id", .Type, .Collection, .Parameters)
	If ..AssertTrue(PropExists, "Property b.id should exist.") {
		Do ..AssertEqual(Type, "%Integer", "Property id should have type %Integer.")
		Do ..AssertEqual(Collection, "", "Property id should have no collection.")
		Do ..AssertEqual($Get(Parameters("XMLPROJECTION")), "ATTRIBUTE", "Property id should have proper XMLPROJECTION.")
	}
	
	;Check a.b.content
	Set PropExists = ..HasProperty(Classname2_"||content", .Type, .Collection, .Parameters)
	If ..AssertTrue(PropExists, "Property b.content should exist.") {
		Do ..AssertEqual(Type, "%String", "Property b.content should have type %String.")
		Do ..AssertEqual(Collection, "", "Property b.content should have no collection.")
		Do ..AssertEqual($Get(Parameters("XMLPROJECTION")), "CONTENT", "Property b.content should have proper XMLPROJECTION.")
	}
	
	;Check if parsed object outputs the same Xml.
	Do ..CheckRoundTrip(ClassName, Xml)
	
	Do $System.OBJ.Delete(ClassName_","_Classname2, "-d")
	
	Quit
}

/// Test members: "collection of things" configuration setting
Method TestMembers()
{
	Set Xml = "<main><m1><p1>m1-1.p1</p1><p2>m1-1.p2</p2></m1><m2><p1>m2.p1</p1><p2>m2.p2</p2></m2><m1><p1>m1-2.p1</p1></m1></main>"
	
	Set FileName = ..TempFile(Xml)
	
	Set Status = ##class(Strix.XML.ToClass).Create(FileName, ..#TestClassPackage, .ClassName)
	If '..AssertStatusOk(Status, "Create class from XML") Quit
	If '..AssertEqual(ClassName, ..#TestClassPackage_".main", "Main class should have expected name.") Quit
	If '..AssertTrue(..ClassExists(ClassName), "Generated class should exist.") Quit
	
	
	If '..GetObject(ClassName, Xml, .Obj) Quit
	;b
	
	;Do $System.OBJ.Delete(ClassName, "-d")
	
	Quit
}

// ===== Helpers

/// Checks whether the specified class exists.
Method ClassExists(Name As %String, Package As %String = "") As %Boolean
{
	If Name '[ "." {
		If Package = "" Set Package = ..#TestClassPackage
		Set Name = Package_"."_Name
	}
	Quit ##class(%Dictionary.ClassDefinition).%ExistsId(Name)
}

/// Checks whether a property exists, returning some information about it
/// if it does.
Method HasProperty(PropertyId As %String, Output Type As %String, Output Collection As %String, Output Parameters As %String) As %Boolean
{
	Kill Type, Collection, Parameters
	
	Set Def = ##class(%Dictionary.PropertyDefinition).%OpenId(PropertyId)
	If '$IsObject(Def) Quit 0
	Set Type = Def.Type
	Set Collection = Def.Collection
	Set Key = ""
	For  {
		Set Value = Def.Parameters.GetNext(.Key)
		If Key = "" Quit
		Set Parameters(Key) = Value
	}
	
	Quit 1
}

/// Checks whether a class parameter exists, returning its value
/// if it does.
Method HasParameter(ParameterId As %String, Output Value As %String) As %Boolean
{
	Set Def = ##class(%Dictionary.ParameterDefinition).%OpenId(ParameterId)
	If '$IsObject(Def) Quit 0
	Set Value = Def.Default
	Quit 1
}

/// Reads the Xml into an object of the specified class, and returns the object.
Method GetObject(ClassName As %String, Xml As %String, Output Object As %XML.Adaptor) As %Boolean
{
	Set Status = $System.OBJ.Compile(ClassName, "crbuk-d")
	If '..AssertStatusOk(Status, "Class {} should compile without error.", ClassName) Quit 0
	
	Set Reader = ##class(%XML.Reader).%New()
	Set Status = Reader.OpenString(Xml)
	If '..AssertStatusOk(Status, "XML reader should parse original XML.") Quit 0
	Do Reader.CorrelateRoot(ClassName)
	
	If '..AssertTrue(Reader.Next(.Object, .Status), "XML Reader should find object in XML.") Quit 0
	If '..AssertStatusOk(Status, "XML reader return ok status from parsing XML.") Quit 0
	
	Quit 1
}

/// Check if provided Xml roundtrips properly.
Method CheckRoundTrip(ClassName As %String, Xml As %String) As %Boolean
{
	#dim Obj As %XML.Adaptor
	If '..GetObject(ClassName, Xml, .Obj) Quit 0
	
	Set Status = Obj.XMLExportToString(.Output)
	If '..AssertStatusOk(Status, "Created object should be able to output XML.") Quit 0
	
	If '..AssertEqual(Output, Xml, "Re-created XML should equal original XML.") Quit 0
	
	Quit 1
}

/// Creates a temporary file with the Xml passed in, and returns its name.
Method TempFile(Xml As %String) As %FileCharacterStream
{
	Set Name = ##class(%File).TempFilename("temp.xml")
	Set File = ##class(%FileCharacterStream).%New()
	Set File.Filename = Name
	Do File.Write(Xml)
	Set Status = File.%Save()
	Do ..TempFiles.Insert(Name)
	Quit Name
}

// ===== Cleanup code.

Method TearDown() As %Status
{
	;Remove generated classes
	Set Status = $System.OBJ.DeletePackage(..#TestClassPackage, "-d")
	If 'Status Quit Status
	
	;Delete temporary files
	For i = 1:1:..TempFiles.Count() {
		Set FileName = ..TempFiles.GetAt(i)
		Do ##class(%File).Delete(FileName)
	}
	
	Quit $$$OK
}

}
