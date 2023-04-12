/// Information about an existing resultset.
Class Strix.Resultset.Info Extends %SerialObject [ StorageStrategy = "" ]
{

/// The id of the resultset containing all results.
Property ResultsetId As %String;

/// The (one-based) number of the first item of the returned results
Property FirstItem As %Integer;

/// The total number of items present in the resultset (not in the
/// returned page)
Property ItemCount As %Integer;

// =====

Storage Default
{
<Data name="InfoState">
<Value name="1">
<Value>ResultsetID</Value>
</Value>
<Value name="2">
<Value>FirstItem</Value>
</Value>
<Value name="3">
<Value>ItemCount</Value>
</Value>
<Value name="4">
<Value>ResultsetId</Value>
</Value>
</Data>
<State>InfoState</State>
<StreamLocation>^Strix.Resultset.InfoS</StreamLocation>
<Type>%Library.CacheSerialState</Type>
}

}

