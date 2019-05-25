<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.Batcher">
<Description>
Resultset-like interface for batched retrieval of data from a collection
of objects. Can be used in a loop to successively get the next batch
until all items have been retrieved.</Description>
<Super>%RegisteredObject</Super>
<TimeCreated>63411,29330.635868</TimeCreated>

<Property name="SourceData">
<Description>
The collection of objects to retrieve the batches from</Description>
<Type>%ListOfObjects</Type>
</Property>

<Property name="BatchSize">
<Description>
The number of objects to retrieve in each batch</Description>
<Type>%Integer</Type>
<InitialExpression>100</InitialExpression>
</Property>

<Property name="CurrentBatch">
<Description>
The current batch, valid after calling Next() (if it returns 1)</Description>
<Type>%ListOfObjects</Type>
</Property>

<Property name="CurrentBatchNr">
<Description>
The (1-based) current batch number.</Description>
<Type>%Integer</Type>
<InitialExpression>0</InitialExpression>
<ReadOnly>1</ReadOnly>
</Property>

<Method name="Get">
<Description>
Constructor; retrieves a new batch iterator.
SourceData contains the list of objects to iterate over.
BatchContainer can contain a reference to a (new or existing) collection,
  or be left empty, in which case a new %ListOfObjects will be created.
  The container is placed in property CurrentBatch, and cleared before
  inserting the next batch.
BatchSize specifies the maximum number of objects per batch.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>SourceData:%Collection.AbstractList,BatchContainer:%Collection.AbstractList="",BatchSize:%Integer=100</FormalSpec>
<Implementation><![CDATA[
	Set Me = ..%New()
	Set Me.SourceData = SourceData
	If BatchContainer {
		Set Me.CurrentBatch = BatchContainer
	} Else {
		Set Me.CurrentBatch = ..GetNewContainer(SourceData)
		Set BatchContainer = Me.CurrentBatch
	}
	Set Me.BatchSize = BatchSize
	Quit Me
]]></Implementation>
</Method>

<Method name="Next">
<Description>
Gets the next batch; returns 0 if the source collection is exhausted, 1 otherwise.</Description>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
	Set i%CurrentBatchNr = i%CurrentBatchNr + 1
	
	Set Start = ((..CurrentBatchNr - 1) * ..BatchSize) + 1
	If Start > ..SourceData.Count() Quit 0
	
	Do ..CurrentBatch.Clear()
	
	For i = Start:1:Start + ..BatchSize - 1 {
		If i > ..SourceData.Count() Quit
		Do ..CurrentBatch.Insert(..SourceData.GetAt(i))
	}
	
	Quit 1
]]></Implementation>
</Method>

<Method name="CopyTo">
<Description>
Copy the contents of the current batch to a different container.
Returns the number of items copied.</Description>
<FormalSpec>Container:%Collection.AbstractList</FormalSpec>
<ReturnType>%Integer</ReturnType>
<Implementation><![CDATA[
	If ..CurrentBatchNr = 0 Quit 0
	If '$IsObject(..CurrentBatch) Quit ""
	
	For i = 1:1:..CurrentBatch.Count() {
		Do Container.Insert(..CurrentBatch.GetAt(i))
	}
	
	Quit Container.Count()
]]></Implementation>
</Method>

<Method name="GetNewContainer">
<Description>
Returns a new container of comparable type to the source.
If the source is of type "list of something", the logical
way of using %ConstructClone doesn't work.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>SourceData:%Collection.AbstractList</FormalSpec>
<ReturnType>%Collection.AbstractList</ReturnType>
<Implementation><![CDATA[
	;Replace %Collection classes as they can't be cloned
	If SourceData.%PackageName() = "%Collection" {
		If $Extract(SourceData.%ClassName(0), *-1, *) = "DT" Quit ##class(%ListOfDataTypes).%New()
		Quit ##class(%ListOfObjects).%New()
	}
	
	Quit SourceData.%ConstructClone(0)
]]></Implementation>
</Method>
</Class>
</Export>
