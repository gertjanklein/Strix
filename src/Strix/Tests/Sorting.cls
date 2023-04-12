Class Strix.Tests.Sorting Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.SortTest";

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	; Create serial class
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName_"Ser", "%SerialObject", .ClassDef)
	If 'Status Quit Status
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "SubProp1", "%String")
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "SubProp2", "%String")
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	;Create a persistent class with a property of type String.
	#dim ClassDef As %Dictionary.ClassDefinition
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%RegisteredObject", .ClassDef)
	If 'Status Quit Status
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop1", "%String")
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop2", "%String")
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "SubProp", ..#TestClassName_"Ser")
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Code to run after all tests in this class have been executed.
Method TearDown() As %Status
{
	Set sc = ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	If 'sc Quit sc
	Set sc = ##class(Strix.Testing.Support).RemoveClass(..#TestClassName_"Ser")
	If 'sc Quit sc
	Quit $$$OK
}

// =====

/// Test basic sort
Method TestBasic()
{
	Set Count = 2
	Set List = ##class(%ListOfObjects).%New()
	For i = 1:1:Count {
		Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
		Set Obj.Prop1 = "Value "_$Justify(i, $Length(Count) + 1)
		Do List.Insert(Obj)
	}
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:D")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	Do ..AssertEqual(List.Count(), Count, "List should have the same number of objects")
	
	Do ..AssertEqual(List.GetAt(1).Prop1, "Value "_$Justify(Count, $Length(Count) + 1), "Largest value should come first.")
	
	Quit
}

/// Test descending sort with large number of objects
Method TestLargeDescending()
{
	Set Count = 1000
	Set List = ##class(%ListOfObjects).%New()
	For i = 1:1:Count {
		Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
		Set Obj.Prop1 = "Value "_$Justify(i, $Length(Count) + 1)
		Do List.Insert(Obj)
	}
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:D")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	Do ..AssertEqual(List.Count(), Count, "List should have the same number of objects")
	
	Set Sorted = 1
	For i = 1:1:List.Count() {
		If i = 1 Set Prev = List.GetAt(i).Prop1 Continue
		Set Value = List.GetAt(i).Prop1
		If Prev ] Value Set Prev = Value Continue
		Set Sorted = 0
		Break
		Quit
	}
	Do ..AssertEqual(Sorted, 1, "List should be sorted.")
	
	Quit
}

/// Test ascending sort with large number of objects
Method TestLargeAscending()
{
	Set Count = 1000
	Set List = ##class(%ListOfObjects).%New()
	For i = Count:-1:1 {
		Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
		Set Obj.Prop1 = "Value "_$Justify(i, $Length(Count) + 1)
		Do List.Insert(Obj)
	}
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:A")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	Do ..AssertEqual(List.Count(), Count, "List should have the same number of objects")
	
	Set Sorted = 1
	For i = 1:1:List.Count() {
		If i = 1 Set Prev = List.GetAt(i).Prop1 Continue
		Set Value = List.GetAt(i).Prop1
		If Value ] Prev Set Prev = Value Continue
		Set Sorted = 0
		Break
		Quit
	}
	Do ..AssertEqual(Sorted, 1, "List should be sorted.")
	
	Quit
}

/// Test objects with equal sort keys stay in the same order
Method TestStable()
{
	
	Set List = ##class(%ListOfObjects).%New()
	For i = 1:1:10 {
		Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
		Set Obj.Prop1 = "Value"
		Set Obj.Prop2 = i
		Do List.Insert(Obj)
	}
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:A")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	Do ..AssertEqual(List.Count(), 10, "List should have the same number of objects")
	
	For i = 1:1:10 {
		If '..AssertEqual(List.GetAt(i).Prop2, i, "Order should not have changed.") Quit
	}
	
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:D")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	Do ..AssertEqual(List.Count(), 10, "List should have the same number of objects")
	
	For i = 1:1:10 {
		If '..AssertEqual(List.GetAt(i).Prop2, i, "Order should not have changed.") Quit
	}
}

/// Test sort on multiple properties, using stable sort by sorting
/// from rightmost to leftmost sort property
Method TestMultiSort()
{
	Set List = ##class(%ListOfObjects).%New()
	
	;Insert in prop1 ascending, prop2 decending order
	For i1 = 1:1:3 {
		For i2 = 3:-1:1 {
			Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
			Set Obj.Prop1 = i1
			Set Obj.Prop2 = i2
			Do List.Insert(Obj)
		}
	}
	
	;== Sort to prop1 decending, prop2 ascending order
	
	;Sort second prop first
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop2:A")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	
	;Sort first prop
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:D")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	
	For i1 = 1:1:3 {
		For i2 = 1:1:3 {
			Set Obj = List.GetAt(i1-1*3+i2)
			If '..AssertEqual(4-i1, Obj.Prop1, "First prop should be sorted descending.") Quit
			If '..AssertEqual(i2, Obj.Prop2, "Second prop should be sorted ascending.") Quit
		}
	}
	
	Quit
}

/// Test sort on multiple properties specified at once.
Method TestMultiSort2()
{
	Set List = ##class(%ListOfObjects).%New()
	
	;Insert in prop1 ascending, prop2 decending order
	For i1 = 1:1:3 {
		For i2 = 3:-1:1 {
			Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
			Set Obj.Prop1 = i1
			Set Obj.Prop2 = i2
			Do List.Insert(Obj)
		}
	}
	
	;== Sort to prop1 decending, prop2 ascending order
	
	;Sort second prop first
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop1:D,Prop2:A")
	Do ..AssertStatusOk(Status, "Sorting code should not return an error.")
	
	For i1 = 1:1:3 {
		For i2 = 1:1:3 {
			Set Obj = List.GetAt(i1-1*3+i2)
			If '..AssertEqual(4-i1, Obj.Prop1, "First prop should be sorted descending.") Quit
			If '..AssertEqual(i2, Obj.Prop2, "Second prop should be sorted ascending.") Quit
		}
	}
	
	Quit
}

/// Tests sorting on a property in a dotted path
Method TestSubProp()
{
	Set Count = 2
	Set List = ##class(%ListOfObjects).%New()
	For i = 1:1:Count {
		Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
		Set Obj.Prop1 = "Value "_$Justify(i, $Length(Count) + 1)
		Set Obj.SubProp.SubProp1 = Count + 1 - i
		Do List.Insert(Obj)
	}
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "SubProp.SubProp1:A")
	If '..AssertStatusOk(Status, "Sorting code should not return an error.") Quit
	If '..AssertEqual(List.Count(), Count, "List should have the same number of objects") Quit
	
	Do ..AssertEqual(List.GetAt(1).Prop1, "Value "_$Justify(Count, $Length(Count) + 1), "Largest value should come first.")
	
	Quit
}

/// Tests sorting on both a direct property and a property in a dotted path
Method TestPropAndSubProp()
{
	Set List = ##class(%ListOfObjects).%New()
	
	; #1
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.Prop1 = 1
	Set Obj.Prop2 = "Value 1"
	Set Obj.SubProp.SubProp1 = 3
	Do List.Insert(Obj)
	
	; #2
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.Prop1 = 2
	Set Obj.Prop2 = "Value 2"
	Set Obj.SubProp.SubProp1 = 2
	Do List.Insert(Obj)
	
	; #2
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.Prop1 = 3
	Set Obj.Prop2 = "Value 2"
	Set Obj.SubProp.SubProp1 = 100
	Do List.Insert(Obj)
	
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(List, "Prop2,SubProp.SubProp1")
	If '..AssertStatusOk(Status, "Sorting code should not return an error.") Quit
	If '..AssertEqual(List.Count(), 3, "List should have the same number of objects") Quit
	
	Do ..AssertEqual(List.GetAt(1).Prop1, 1, "Obj 1 still first.")
	Do ..AssertEqual(List.GetAt(2).Prop1, 3, "Obj 3 now second.")
	Do ..AssertEqual(List.GetAt(3).Prop1, 2, "Obj 2 now last.")
	
	Quit
}

}
