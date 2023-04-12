/// Test code for class Strix.JSON.Adaptor
Class Strix.Tests.JSONAdaptor Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.JSONAdaptorTest";

/// Code to run after all tests in this class have been executed.
Method TearDown() As %Status
{
	Quit ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
}

// =====

/// Test basic JSON conversion
Method TestBasicExport()
{
	; Create class
	
	Set Status = ..CreateClass("String:%String,Bool:%Boolean")
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.String = "a"
	Set Obj.Bool = "1"
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	Do ..AssertEqual(DynObj.string, "a", "String property should have value 'a'.")
	Do ..AssertEqual(DynObj.%GetTypeOf("string"), "string", "String property should have type string.")
	
	Do ..AssertEqual(DynObj.bool, "1", "Boolean property should have value true.")
	Do ..AssertEqual(DynObj.%GetTypeOf("bool"), "boolean", "Boolean property should have type boolean.")
	
	Quit
}

/// Tests lists of datatypes are projected as arrays
Method TestExportListOfDT()
{
	; Create class
	
	Set Status = ..CreateClass("Strings:%String:list,Bools:%Boolean:list")
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Do Obj.Strings.Insert("a")
	Do Obj.Strings.Insert("b")
	Do Obj.Bools.Insert(0)
	Do Obj.Bools.Insert(1)
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	If ..AssertEqual(DynObj.%GetTypeOf("strings"), "array", "Strings should be an array.") {
		Do ..AssertEqual(DynObj.strings.%Get(0), "a", "Strings item 0 should have correct value")
		Do ..AssertEqual(DynObj.strings.%GetTypeOf(0), "string", "Strings items should have correct type.")
		Do ..AssertEqual(DynObj.strings.%Get(1), "b", "Strings item 1 should have correct value")
	}
	
	If ..AssertEqual(DynObj.%GetTypeOf("bools"), "array", "Bools should be an array.") {
		Do ..AssertEqual(DynObj.bools.%Get(0), 0, "Bools item 0 should have correct value.")
		Do ..AssertEqual(DynObj.bools.%GetTypeOf(0), "boolean", "Bools items should have correct type.")
		Do ..AssertEqual(DynObj.bools.%Get(1), 1, "Bools item 1 should have correct value.")
	}	
	
	Quit
}

/// Tests specifying different JSON name
Method TestRename()
{
	; Create class
	
	Set Status = ..CreateClass("String1:%String,String2:%String", .ClassDef)
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	Set Status = ##class(Strix.Testing.Support).SetPropertyParameter(ClassDef, "String2", "JSONNAME", "otherName", 1)
	If '..AssertStatusOk(Status, "Should be able to set property parameter.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.String1 = "a"
	Set Obj.String2 = "b"
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	Do ..AssertEqual(DynObj.string1, "a", "String1 property should be present and have value 'a'.")
	Do ..AssertEqual(DynObj.otherName, "b", "String2 property should be present as otherName and have value 'b'.")
	
	
	Quit
}

/// Tests specifying a JSON projection of NONE on export
Method TestExportJSONIONONE()
{
	; Create class
	
	Set Status = ..CreateClass("String1:%String,String2:%String", .ClassDef)
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	Set Status = ##class(Strix.Testing.Support).SetPropertyParameter(ClassDef, "String2", "JSONIO", "NONE", 1)
	If '..AssertStatusOk(Status, "Should be able to set property parameter.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.String1 = "a"
	Set Obj.String2 = "b"
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	Do ..AssertEqual(DynObj.%GetTypeOf("string1"), "string", "String1 property should be present.")
	Do ..AssertEqual(DynObj.%GetTypeOf("string2"), "unassigned", "String2 property should not be present.")
	
	
	Quit
}

/// Tests specifying a JSON projection of IN on export
Method TestExportJSONIOIN()
{
	; Create class
	
	Set Status = ..CreateClass("String1:%String,String2:%String", .ClassDef)
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	Set Status = ##class(Strix.Testing.Support).SetPropertyParameter(ClassDef, "String2", "JSONIO", "IN", 1)
	If '..AssertStatusOk(Status, "Should be able to set property parameter.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.String1 = "a"
	Set Obj.String2 = "b"
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	Do ..AssertEqual(DynObj.%GetTypeOf("string1"), "string", "String1 property should be present.")
	Do ..AssertEqual(DynObj.%GetTypeOf("string2"), "unassigned", "String2 property should not be present.")
	
	
	Quit
}

/// Tests export of nested objects
Method TestExportDelegation()
{
	; Create class
	
	Set Status = ..CreateClass("String1:%String,SubObj:"_..#TestClassName, .ClassDef)
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	
	; Create instance
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.String1 = "a"
	Set SubObj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.SubObj = SubObj
	Set SubObj.String1 = "b"
	
	; Test
	
	#dim DynObj As %DynamicObject
	Set DynObj = Obj.JSONExport(.Status)
	Do ..AssertStatusOk(Status, "JSON export should not return an error.")
	Do ..Assert($IsObject(DynObj), "JSON Export should return a %DynamicObject.")
	
	Do ..AssertEqual(DynObj.%GetTypeOf("string1"), "string", "String1 property should be present.")
	If '..AssertEqual(DynObj.%GetTypeOf("subObj"), "object", "SubObj property should be present and be an object.") Quit
	Do ..AssertEqual(DynObj.subObj.string1, "b", "SubObj.String1 property should have value 'b'.")
	
	
	Quit
}

// ===== Helpers

/// Create a class with the specified properties
ClassMethod CreateClass(Properties As %String = "", Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%RegisteredObject,Strix.JSON.Adaptor", .ClassDef)
	If 'Status Quit Status
	
	If Properties '= "" {
		For i = 1:1:$Length(Properties, ",") {
			Set Def = $Piece(Properties, ",", i)
			Set Name = $Piece(Def, ":", 1)
			Set Type = $Piece(Def, ":", 2)
			Set Coll = $Piece(Def, ":", 3)
			Do ##class(Strix.Testing.Support).AddProperty(ClassDef, Name, Type, Coll)
		}
	}
	
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
}

}
