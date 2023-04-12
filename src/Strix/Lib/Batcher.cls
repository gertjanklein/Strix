/// Resultset-like interface for batched retrieval of data from a collection
/// of objects. Can be used in a loop to successively get the next batch
/// until all items have been retrieved.
Class Strix.Lib.Batcher Extends %RegisteredObject
{

/// The collection of objects to retrieve the batches from
Property SourceData As %ListOfObjects;

/// The number of objects to retrieve in each batch
Property BatchSize As %Integer [ InitialExpression = 100 ];

/// The current batch, valid after calling Next() (if it returns 1)
Property CurrentBatch As %ListOfObjects;

/// The (1-based) current batch number.
Property CurrentBatchNr As %Integer [ InitialExpression = 0, ReadOnly ];

/// Constructor; retrieves a new batch iterator.
/// SourceData contains the list of objects to iterate over.
/// BatchContainer can contain a reference to a (new or existing) collection,
///   or be left empty, in which case a new %ListOfObjects will be created.
///   The container is placed in property CurrentBatch, and cleared before
///   inserting the next batch.
/// BatchSize specifies the maximum number of objects per batch.
ClassMethod Get(SourceData As %Collection.AbstractList, BatchContainer As %Collection.AbstractList = "", BatchSize As %Integer = 100)
{
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
}

/// Gets the next batch; returns 0 if the source collection is exhausted, 1 otherwise.
Method Next() As %Boolean
{
	Set i%CurrentBatchNr = i%CurrentBatchNr + 1
	
	Set Start = ((..CurrentBatchNr - 1) * ..BatchSize) + 1
	If Start > ..SourceData.Count() Quit 0
	
	Do ..CurrentBatch.Clear()
	
	For i = Start:1:Start + ..BatchSize - 1 {
		If i > ..SourceData.Count() Quit
		Do ..CurrentBatch.Insert(..SourceData.GetAt(i))
	}
	
	Quit 1
}

/// Copy the contents of the current batch to a different container.
/// Returns the number of items copied.
Method CopyTo(Container As %Collection.AbstractList) As %Integer
{
	If ..CurrentBatchNr = 0 Quit 0
	If '$IsObject(..CurrentBatch) Quit ""
	
	For i = 1:1:..CurrentBatch.Count() {
		Do Container.Insert(..CurrentBatch.GetAt(i))
	}
	
	Quit Container.Count()
}

/// Returns a new container of comparable type to the source.
/// If the source is of type "list of something", the logical
/// way of using %ConstructClone doesn't work.
ClassMethod GetNewContainer(SourceData As %Collection.AbstractList) As %Collection.AbstractList
{
	;Replace %Collection classes as they can't be cloned
	If SourceData.%PackageName() = "%Collection" {
		If $Extract(SourceData.%ClassName(0), *-1, *) = "DT" Quit ##class(%ListOfDataTypes).%New()
		Quit ##class(%ListOfObjects).%New()
	}
	
	Quit SourceData.%ConstructClone(0)
}

}
