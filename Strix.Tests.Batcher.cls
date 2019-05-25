<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.Batcher">
<Description>
Test code for class Strix.Lib.Batcher</Description>
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>63863,77720.622688</TimeCreated>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="TestDataType">
<Description>
Test batcher with ordinary strings</Description>
<Implementation><![CDATA[
	Set List = ##class(%ListOfDataTypes).%New()
	For i = 1:1:10 Do List.Insert(i)
	
	Set BatchSize = 2
	
	#dim Batcher As Strix.Lib.Batcher
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List, , BatchSize)
	While Batcher.Next() {
		Set Batch = Batcher.CurrentBatch
		
		;Determine contents of first item of this batch
		Set First = Batcher.CurrentBatchNr - 1 * BatchSize + 1
		
		;Check all items
		Set Ok = 1
		For i = 1:1:BatchSize {
			If Batch.GetAt(i) = (First + i - 1) Continue
			Set Ok = 0
			Quit
		}
		Do ..AssertTrue(Ok, "Batch should contain the proper items.")
	}
	
	Quit
]]></Implementation>
</Method>

<Method name="TestContainerType">
<Description>
Test using the proper container type for CurrentBatch</Description>
<Implementation><![CDATA[
	#dim Batcher As Strix.Lib.Batcher
	
	;Normal %ListOfXxx classes: container should be of same type
	
	Set List = ##class(%ListOfObjects).%New()
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List)
	Do ..AssertEqual(Batcher.CurrentBatch.%ClassName(1), List.%ClassName(1), "Batcher should return object container for %ListOfObjects.")
	
	Set List = ##class(%ListOfDataTypes).%New()
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List)
	Do ..AssertEqual(Batcher.CurrentBatch.%ClassName(1), List.%ClassName(1), "Batcher should return datatype container for %ListOfDataTypes.")
	
	;%Collection.Xxx classes: container should be %ListOfXxx, as the %Collection.Xxx,
	;when a property of an object, can't be cloned.
	
	Set List = ##class(%Collection.ListOfObj).%New()
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List)
	Do ..AssertEqual(Batcher.CurrentBatch.%ClassName(1), "%Library.ListOfObjects", "Batcher should return object container for %Collection.ListOfObj.")
	
	Set List = ##class(%Collection.ListOfDT).%New()
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List)
	Do ..AssertEqual(Batcher.CurrentBatch.%ClassName(1), "%Library.ListOfDataTypes", "Batcher should return datatype container for %Collection.ListOfDT.")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestEmpty">
<Description>
Test Next() returns 0 on empty collection</Description>
<Implementation><![CDATA[
	#dim Batcher As Strix.Lib.Batcher
	
	Set List = ##class(%ListOfObjects).%New()
	Set Batcher = ##class(Strix.Lib.Batcher).Get(List)
	Do ..AssertEqual(Batcher.Next(), 0, "Batcher.Next() should not return 1 if collection empty.")
	
	Quit
]]></Implementation>
</Method>
</Class>
</Export>
