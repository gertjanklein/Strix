<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.Sorting">
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>63863,51706.130408</TimeCreated>

<Parameter name="TestClassName">
<Default>Strix.Tests.Temp.SortTest</Default>
</Parameter>

<Method name="Setup">
<Description>
Code to run before any test in this class is executed.</Description>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	;Create a persistent class with a property of type String.
	
	#dim ClassDef As %Dictionary.ClassDefinition
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%RegisteredObject", .ClassDef)
	If 'Status Quit Status
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop1", "%String")
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop2", "%String")
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="TearDown">
<Description>
Code to run after all tests in this class have been executed.</Description>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[	Quit ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="TestBasic">
<Description>
Test basic sort</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestLargeDescending">
<Description>
Test descending sort with large number of objects</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestLargeAscending">
<Description>
Test ascending sort with large number of objects</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestStable">
<Description>
Test objects with equal sort keys stay in the same order</Description>
<Implementation><![CDATA[
	
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
]]></Implementation>
</Method>

<Method name="TestMultiSort">
<Description>
Test sort on multiple properties, using stable sort by sorting
from rightmost to leftmost sort property</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="TestMultiSort2">
<Description>
Test sort on multiple properties specified at once.</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>
</Class>
</Export>
