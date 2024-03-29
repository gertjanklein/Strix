/// Tests Strix.JSON.ToClass.
Class Strix.Tests.JSONToClass Extends Strix.Testing.TestCase
{

/// Base package for created test classes
Parameter TestClassPackage = "TestJSONToClass";

// ===== Tests

/// Test creating simple test class with one property
Method TestBasic()
{
	Set JSON = { "a": 1, "b": "2", "c": [ 1, 2, 3 ] }
	
	;Create class
	
	Set ClassName = ..#TestClassPackage_".TB"
	Set Status = ##class(Strix.JSON.ToClass).Create(JSON, ClassName)
	If '..AssertStatusOk(Status, "Create should run without error.") Quit 0
	
	; Check expected properties
	
	Set PropExists = ..HasProperty(ClassName_"||A", .Type, .Collection, .Parameters)
	If ..Assert(PropExists, "Property A should exist.") {
		Do ..AssertEqual(Type, "%Numeric", "Property A should be numeric.")
		Do ..AssertEqual(Collection, "", "Property A should have no collection.")
		Do ..AssertEqual($Get(Parameters("JSONNAME")), "a", "Property 'A' should project to JSON field 'a'.")
	}
	Kill Parameters
	
	Set PropExists = ..HasProperty(ClassName_"||B", .Type, .Collection, .Parameters)
	If ..Assert(PropExists, "Property B should exist.") {
		Do ..AssertEqual(Type, "%String", "Property B should be a string.")
		Do ..AssertEqual(Collection, "", "Property B should have no collection.")
		Do ..AssertEqual($Get(Parameters("JSONNAME")), "b", "Property 'B' should project to JSON field 'b'.")
	}
	Kill Parameters
	
	Set PropExists = ..HasProperty(ClassName_"||C", .Type, .Collection, .Parameters)
	If ..Assert(PropExists, "Property C should exist.") {
		Do ..AssertEqual(Type, "%Numeric", "Property C should be of type string.")
		Do ..AssertEqual(Collection, "list", "Property C should be a list.")
		Do ..AssertEqual($Get(Parameters("JSONNAME")), "c", "Property 'C' should project to JSON field 'c'.")
	}
	Kill Parameters
	
	; Read data into instance of new class
	
	If '..Assert(..GetObject(ClassName, JSON, , .Obj)) Quit
	
	; Check property contents
	
	Do ..AssertEqual(Obj.A, 1, "Object should have read property A.")
	Do ..AssertEqual(Obj.B, "2", "Object should have read property B.")
	If ..AssertEqual(Obj.C.Count(), 3, "Object should have read property C.") {
		Do ..AssertEqual(Obj.C.GetAt(1), 1, "First value of property C.")
		Do ..AssertEqual(Obj.C.GetAt(2), 2, "Second value of property C.")
		Do ..AssertEqual(Obj.C.GetAt(3), 3, "Third value of property C.")
	}
	
	; Get JSON from object
	
	Set Out = Obj.JSONExport(, , .Status)
	If '..AssertStatusOk(Status, "Export object data to JSON") Quit
	
	; Make sure it round-trips.
	
	Set InAsStr = JSON.%ToJSON()
	Set OutAsStr = Out.%ToJSON()
	
	Do ..AssertEqual(OutAsStr, InAsStr, "JSON should round-trip.")
	
	Quit
}

/// Test auto-rename of properties
Method TestpropertyNames()
{
	Set JSON = {
		"many-separated-parts-dash": "",
		"many_separated_parts_underscore": "",
		"many_separated-parts_mixed": "",
		"42": ""
	}
	
	;Create class
	
	Set ClassName = ..#TestClassPackage_".TB"
	Set Status = ##class(Strix.JSON.ToClass).Create(JSON, ClassName)
	If '..AssertStatusOk(Status, "Create should run without error.") Quit 0
	
	; Check expected properties
	
	If ..Assert(..CheckProp(ClassName, "ManySeparatedPartsDash"), "Dash-separated name")
	If ..Assert(..CheckProp(ClassName, "ManySeparatedPartsUnderscore"), "Underscore-separated name")
	If ..Assert(..CheckProp(ClassName, "ManySeparatedPartsMixed"), "Underscore- and dash-separated name")
	If ..Assert(..CheckProp(ClassName, "n42"), "All-numeric name")
	
	; Read data into instance of new class
	
	If '..Assert(..GetObject(ClassName, JSON, , .Obj)) Quit
	
	; Get JSON from object
	
	Set Out = Obj.JSONExport(, , .Status)
	If '..AssertStatusOk(Status, "Export object data to JSON") Quit
	
	; Make sure it round-trips. This also tests JSONNAME.
	
	Set InAsStr = JSON.%ToJSON()
	Set OutAsStr = Out.%ToJSON()
	
	Do ..AssertEqual(OutAsStr, InAsStr, "JSON should round-trip.")
	
	Quit
}

/// Test basic sparse output (skipping empty properties).
Method TestSparseBasic()
{
	Set JSON = { "a": "1", "b": "", "c": "3" }
	
	;Create class
	
	Set ClassName = ..#TestClassPackage_".TB"
	Set Status = ##class(Strix.JSON.ToClass).Create(JSON, ClassName)
	If '..AssertStatusOk(Status, "Create should run without error.") Quit
	
	; Check expected properties
	
	Do ..Assert(..CheckProp(ClassName, "A"), "Property A should exist")
	Do ..Assert(..CheckProp(ClassName, "B"), "Property B should exist")
	Do ..Assert(..CheckProp(ClassName, "C"), "Property C should exist")
	
	#dim Obj As Strix.JSON.Adaptor
	If '..Assert(..GetObject(ClassName, JSON, , .Obj)) Quit
	
	; Get sparse JSON from object
	
	Set Out = Obj.JSONExport(1, , .Status)
	If '..AssertStatusOk(Status, "Export object data to JSON") Quit
	
	; Make sure it round-trips.
	
	Set OutAsStr = Out.%ToJSON()
	Set Expected = { "a": "1", "c": "3" }.%ToJSON()
	Do ..AssertEqual(OutAsStr, Expected, "Empty property should not be present in output.")
	
	Quit
}

/// Test creating single sub-object
Method TestSubObj()
{
	Set JSON = { "a": "1", "b": { "x": "1", "y": "", "z": "3" }, "c": "3" }
	
	;Create class
	
	Set ClassName = ..#TestClassPackage_".TB"
	Set Status = ##class(Strix.JSON.ToClass).Create(JSON, ClassName)
	If '..AssertStatusOk(Status, "Create should run without error.") Quit
	If '..Assert(..ClassExists("B"), "Subclass should be created.") Quit
	
	; Check object-type property
	
	If '..Assert(..CheckProp(ClassName, "B", .Type), "Property B should exist") Quit
	If '..AssertEqual(Type, ..#TestClassPackage_".B", "Property B should have type B.") Quit
	
	; Get object from JSON
	
	#dim Obj As Strix.JSON.Adaptor
	If '..Assert(..GetObject(ClassName, JSON, , .Obj)) Quit
	
	; Test access of a subobject property
	
	If '..AssertEqual(Obj.B.Z, "3", "Subobject property should have proper value.") Quit
	
	; Get JSON from object
	
	Set Out = Obj.JSONExport(, , .Status)
	If '..AssertStatusOk(Status, "Export object data to JSON") Quit
	
	; Make sure it round-trips. This also tests JSONNAME.
	
	Set InAsStr = JSON.%ToJSON()
	Set OutAsStr = Out.%ToJSON()
	
	Do ..AssertEqual(OutAsStr, InAsStr, "JSON should round-trip.")
	
	Quit
}

/// Tests whether mixed datatype, but all string or number,
/// are accepted in a list.
Method TestListDataTypes()
{
	Set JSON = { "a": [1, "a"] }
	
	;Create class
	
	Set ClassName = ..#TestClassPackage_".TB"
	Set Status = ##class(Strix.JSON.ToClass).Create(JSON, ClassName)
	If '..AssertStatusOk(Status, "Create should run without error.") Quit
	
	; Check property
	
	If '..Assert(..CheckProp(ClassName, "A", .Type, .Collection), "Property A should exist") Quit
	Do ..AssertEqual(Type, "%String", "Mixed property should be set to string.")
	Do ..AssertEqual(Collection, "list", "Array should result in list.")
	
	; Get object from JSON
	
	#dim Obj As Strix.JSON.Adaptor
	If '..Assert(..GetObject(ClassName, JSON, , .Obj)) Quit
	
	; Get JSON from object
	
	Set Out = Obj.JSONExport(, , .Status)
	If '..AssertStatusOk(Status, "Export object data to JSON") Quit
	
	; Make sure the data is what we expect: strings
	
	Set Result = Out.%ToJSON()
	Set Expected = { "a": ["1", "a"] }.%ToJSON()
	
	Do ..AssertEqual(Result, Expected, "JSON should have all values as string.")
	
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

Method CheckProp(ClassName As %String, PropertyName As %String, Output Type As %String, Output Collection As %String, Output JSONName As %String) As %Boolean
{
	Set Pd = ##class(%Dictionary.PropertyDefinition).%OpenId(ClassName_"||"_PropertyName, , .Status)
	If 'Status Quit 0
	Set Type = Pd.Type
	Set Collection = Pd.Collection
	Set JSONName = Pd.Parameters.GetAt("JSONNAME")
	Quit 1
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

/// Reads the JSON into an object of the specified class, and returns the object.
Method GetObject(ClassName As %String, JSON As %DynamicObject, Spec As %String, Output Object As Strix.JSON.Adaptor) As %Boolean
{
	Set Status = $System.OBJ.Compile(ClassName, "crbuk-d")
	If '..AssertStatusOk(Status, "Class {} should compile without error.", ClassName) Quit 0
	
	Set Object = $ZObjClassMethod(ClassName, "CreateFromJSON", JSON, .Spec, .Status)
	If '..AssertStatusOk(Status, "JSON should be read without error.") Quit 0
	
	Quit 1
}

// ===== Cleanup code.

Method TearDown() As %Status
{
	; Remove generated classes
	
	Set Status = $System.OBJ.DeletePackage(..#TestClassPackage, "-d")
	If 'Status Quit Status
	
	Quit $$$OK
}

}
