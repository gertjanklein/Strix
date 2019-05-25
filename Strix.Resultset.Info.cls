<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Resultset.Info">
<Description>
Information about an existing resultset.</Description>
<StorageStrategy/>
<Super>%SerialObject</Super>
<TimeCreated>63664,36770.178622</TimeCreated>

<Property name="ResultsetId">
<Description>
The id of the resultset containing all results.</Description>
<Type>%String</Type>
</Property>

<Property name="FirstItem">
<Description>
The (one-based) number of the first item of the returned results</Description>
<Type>%Integer</Type>
</Property>

<Property name="ItemCount">
<Description>
The total number of items present in the resultset (not in the
returned page)</Description>
<Type>%Integer</Type>
</Property>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Storage name="Default">
<Type>%Library.CacheSerialState</Type>
<State>InfoState</State>
<StreamLocation>^Strix.Resultset.InfoS</StreamLocation>
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
</Storage>
</Class>
</Export>
