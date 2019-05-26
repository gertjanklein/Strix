/// Test code for class Strix.JSON.Adaptor
Class Strix.Tests.JSONProperty Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.JSONPropertyTest";

/// Code to run after all tests in this class have been executed.
Method TearDown() As %Status
{
	Do $ZObjClassMethod(..#TestClassName, "%KillExtent")
	Do ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	Quit $$$OK
}

// =====

/// Test basic JSON conversion
Method TestBasic()
{
	If '..AssertStatusOk(..CreateClass("a,b:JSON,c:Str")) Quit
	
	
	; =====
	; Create object, store object values, check
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.a = {}, Obj.b = {}, Obj.c = {}
	
	
	If ..Assert($IsObject(Obj.a), "Property a should still be a dynamic object.") {
		Do ..AssertEqual(Obj.a.%ToJSON(), "{}", "Dynamic object (a) should equal original value.")
	}
	If ..Assert($IsObject(Obj.b), "Property b should be a dynamic object.") {
		Do ..AssertEqual(Obj.b.%ToJSON(), "{}", "Dynamic object (b) should equal original value.")
	}
	Do ..AssertEqual(Obj.c, "{}", "Property c should be converted to a string.")
	
	; Save, reload, check again
	
	If ..AssertStatusOk(Obj.%Save(), "Object should save without error.") {
		Set Id = Obj.%Id() Kill Obj Set Obj = $ZObjClassMethod(..#TestClassName, "%OpenId", Id, , .Status)
		If '..AssertStatusOk(Status, "Obj should re-open.") Quit
		
		Do ..AssertEqual(Obj.a, "{}", "Property a should be a string after reload.")
		If ..Assert($IsObject(Obj.b), "Property b should be a dynamic object after reload.") {
			Do ..AssertEqual(Obj.b.%ToJSON(), "{}", "Dynamic object (b) should equal original value after reload.")
		}
		Do ..AssertEqual(Obj.c, "{}", "Property (c) should remain a string after reload.")
	}
	
	
	; =====
	; Create object, store string values, check
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.a = "{}", Obj.b = "{}", Obj.c = "{}"
	
	Do ..AssertEqual(Obj.a, "{}", "Property a should remain a string.")
	If ..Assert($IsObject(Obj.b), "Property b should be converted to a dynamic object.") {
		Do ..AssertEqual(Obj.b.%ToJSON(), "{}", "Dynamic object (b) should equal original value.")
	}
	Do ..AssertEqual(Obj.c, "{}", "Property c should remain a string.")
	
	; Save, reload, check again
	
	If ..AssertStatusOk(Obj.%Save(), "Object should save without error.") {
		Set Id = Obj.%Id() Kill Obj Set Obj = $ZObjClassMethod(..#TestClassName, "%OpenId", Id, , .Status)
		If '..AssertStatusOk(Status, "Obj should re-open.") Quit
		
		Do ..AssertEqual(Obj.a, "{}", "Property a should remain a string after reload.")
		If ..Assert($IsObject(Obj.b), "Property b should be a dynamic object after reload.") {
			Do ..AssertEqual(Obj.b.%ToJSON(), "{}", "Dynamic object b should equal original value after reload.")
		}
		Do ..AssertEqual(Obj.c, "{}", "Property c should remain a string after reload.")
	}
	
	
	; =====
	; Create object, store empty values, check
	
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.a = "", Obj.b = "", Obj.c = ""
	
	Do ..AssertEqual(Obj.a, "", "Property a should be an empty string.")
	Do ..AssertEqual(Obj.b, "", "Property b should be an empty string.")
	Do ..AssertEqual(Obj.c, "", "Property c should be an empty string.")
	
	; Save, reload, check again
	
	If ..AssertStatusOk(Obj.%Save(), "Object should save without error.") {
		Set Id = Obj.%Id() Kill Obj Set Obj = $ZObjClassMethod(..#TestClassName, "%OpenId", Id, , .Status)
		If '..AssertStatusOk(Status, "Obj should re-open.") Quit
		
		Do ..AssertEqual(Obj.a, "", "Property a should remain an empty string after reload.")
		Do ..AssertEqual(Obj.b, "", "Property b should remain an empty string after reload.")
		Do ..AssertEqual(Obj.c, "", "Property c should remain an empty string after reload.")
	}
	
	Quit
}

// ===== Helpers

/// Create a class with the specified properties
ClassMethod CreateClass(Properties As %String = "", Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%Persistent,Strix.JSON.Adaptor", .ClassDef)
	If 'Status Quit Status
	
	If Properties '= "" {
		For i = 1:1:$Length(Properties, ",") {
			Set Item = $Piece(Properties, ",", i)
			Set Name = $Piece(Item, ":", 1)
			Set Conv = $Piece(Item, ":", 2)
			#dim Def As %Dictionary.PropertyDefinition
			Set Def = ##class(Strix.Testing.Support).AddProperty(ClassDef, Name, "Strix.JSON.Property")
			If Conv '= "" Do Def.Parameters.SetAt(Conv, "Conversion")
		}
	}
	
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
}

}

