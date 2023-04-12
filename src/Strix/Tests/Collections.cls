/// Tests Strix.Lib.Collections.
Class Strix.Tests.Collections Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.Collections";

// =====

/// Basic tests
Method TestCommonElementsBasic()
{
	Set a = ..GetListOfDT("a", "b", "c")
	Set b = ..GetListOfDT("b", "c", "d")
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(a, b)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), "b", "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), "c", "Second result should match.")
	
	; Skip an item in first list
	
	Set a = ..GetListOfDT("b", "a", "c")
	Set b = ..GetListOfDT("b", "c", "d")
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(a, b)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), "b", "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), "c", "Second result should match.")
	
	; Order should be that of first list
	
	Set a = ..GetListOfDT("c", "b", "a")
	Set b = ..GetListOfDT("b", "c", "d")
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(a, b)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), "c", "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), "b", "Second result should match.")
	
	; One empty list means no results
	
	Set a = ..GetListOfDT("c", "b", "a")
	Set b = ..GetListOfDT()
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(a, b)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 0, "Method should return no common elements.")
	
	Quit
}

/// Test input as list of lists
Method TestCommonElementsLoL()
{
	Set a = ..GetListOfDT("a", "b", "c")
	Set b = ..GetListOfDT("b", "c", "d")
	Set Lists = ..GetListOfObjects(a, b)
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(Lists)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), "b", "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), "c", "Second result should match.")
	
	Quit
}

/// Test %Collection.ListOfDT input
Method TestCommonElementsInClass()
{
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Do ..Insert(Obj.a, "a", "b", "c")
	Do ..Insert(Obj.b, "b", "c", "d")
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(Obj.a, Obj.b)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfDataTypes", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), "b", "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), "c", "Second result should match.")
	
	Quit
}

/// Test list of objects input. Comparisons should be done
/// on Oref.
Method TestCommonElementsObjects()
{
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set a = Obj.%New(), b = Obj.%New(), c = Obj.%New(), d = Obj.%New()
	Do ..Insert(Obj.c, a, b, c)
	Do ..Insert(Obj.d, b, c, d)
	
	Set Result = ##class(Strix.Lib.Collections).CommonListElements(Obj.c, Obj.d)
	Do ..AssertEqual(Result.%ClassName(0), "%ListOfObjects", "Method should return proper list object")
	Do ..AssertEqual(Result.Count(), 2, "Method should return 2 common elements.")
	Do ..AssertEqual(Result.GetAt(1), b, "First result should match.")
	Do ..AssertEqual(Result.GetAt(2), c, "Second result should match.")
	
	Quit
}

// =====

Method TestGetCopy()
{
	Set ClassName = ..#TestClassName_"2"
	Set Type = ..#TestClassName
	Set Status = ..CreateClass(ClassName, "a:%String:list,b:%String:array,c:"_Type_":list,d:"_Type_":array")
	If '..AssertStatusOk(Status, "Create test class") Quit
	Set Inst = $ZObjClassMethod(ClassName, "%New")
	
	; Test replacing %Collection-type collections
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.a)
	Do ..AssertEqual(Copy.%ClassName(), "%ListOfDataTypes", "Get proper collection type for property a.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.b)
	Do ..AssertEqual(Copy.%ClassName(), "%ArrayOfDataTypes", "Get proper collection type for property b.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.c)
	Do ..AssertEqual(Copy.%ClassName(), "%ListOfObjects", "Get proper collection type for property c.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.d)
	Do ..AssertEqual(Copy.%ClassName(), "%ArrayOfObjects", "Get proper collection type for property d.")
	
	Kill Inst
	Do ##class(Strix.Testing.Support).RemoveClass(ClassName)
	
	; Test normal %Library collections
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(##class(%ListOfDataTypes).%New())
	Do ..AssertEqual(Copy.%ClassName(), "%ListOfDataTypes", "Get proper collection type for property a.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(##class(%ArrayOfDataTypes).%New())
	Do ..AssertEqual(Copy.%ClassName(), "%ArrayOfDataTypes", "Get proper collection type for property b.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(##class(%ListOfObjects).%New())
	Do ..AssertEqual(Copy.%ClassName(), "%ListOfObjects", "Get proper collection type for property c.")
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(##class(%ArrayOfObjects).%New())
	Do ..AssertEqual(Copy.%ClassName(), "%ArrayOfObjects", "Get proper collection type for property d.")
	
	Quit
}

/// Simple test to make sure contents is copied without error.
Method TestGetCopyWithContents()
{
	Set Inst = $ZObjClassMethod(..#TestClassName, "%New")
	Do Inst.a.Insert("value")
	Do Inst.e.SetAt("value", "key")
	
	; Test copying of list contents
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.a, 1, .sc)
	If ..AssertStatusOk(sc, "Create copy should not return an error.") {
		Do ..AssertEqual(Copy.%ClassName(), "%ListOfDataTypes", "Get the right collection type for property a.")
		Do ..AssertEqual(Copy.Count(), 1, "Copy of property a should have one value.")
		Set Value = Copy.GetAt(1)
		Do ..AssertEqual(Value, "value", "Copy of property a should have the right value.")
	}
	
	; Test copying of array contents
	
	Set Copy = ##class(Strix.Lib.Collections).GetCopy(Inst.e, 1, .sc)
	If ..AssertStatusOk(sc, "Create copy should not return an error.") {
		Do ..AssertEqual(Copy.%ClassName(), "%ArrayOfDataTypes", "Get the right collection type for property e.")
		Do ..AssertEqual(Copy.Count(), 1, "Copy of property e should have one value.")
		Set Key = "", Value = Copy.GetNext(.Key)
		Do ..AssertEqual(Key, "key", "Copy of property e should have the right key.")
		Do ..AssertEqual(Value, "value", "Copy of property e should have the right value.")
	}
	
	Quit
}

// ===== Helpers

Method GetListOfDT(Contents...) As %ListOfDataTypes
{
	Set Result = ##class(%ListOfDataTypes).%New()
	For i = 1:1:$Get(Contents) Do Result.Insert($Get(Contents(i)))
	Quit Result
}

Method GetListOfObjects(Lists...) As %ListOfObjects
{
	Set Result = ##class(%ListOfObjects).%New()
	For i = 1:1:$Get(Lists) Do Result.Insert($Get(Lists(i)))
	Quit Result
}

Method Insert(List As %Collection.AbstractList, Items...)
{
	For i = 1:1:$Get(Items) Do List.Insert(Items(i))
}

/// Create a class with the specified properties
ClassMethod CreateClass(ClassName As %String, Properties As %String = "") As %Status
{
	Set Status = ##class(Strix.Testing.Support).CreateClass(ClassName, "%RegisteredObject", .ClassDef)
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

// =====

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	Set Type = ..#TestClassName
	Set Status = ..CreateClass(Type, "a:%String:list,b:%String:list,c:"_Type_":list,d:"_Type_":list,e:%String:array")
	If 'Status Quit Status
	Quit $$$OK
}

/// Code to run after all tests in this class have been executed.
Method TearDown() As %Status
{
	Do ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	Quit $$$OK
}

}
