<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Background.ItemInfo">
<Description>
This class describes the results of a single item handled in a job
(i.e., by a subclass of the Job class).</Description>
<Super>%SerialObject,%XML.Adaptor</Super>
<TimeCreated>63419,42228.066507</TimeCreated>

<Property name="IsError">
<Description>
Whether this item describes an error</Description>
<Type>%Boolean</Type>
</Property>

<Property name="Message">
<Description>
Textual description</Description>
<Type>%String</Type>
<Parameter name="MAXLEN"/>
</Property>

<Property name="Status">
<Description>
If available, a %Status with error information</Description>
<Type>%Status</Type>
</Property>

<Property name="RelatedId">
<Description>
If this item describes a specific object, it's id</Description>
<Type>%String</Type>
<Parameter name="MAXLEN"/>
</Property>

<Method name="GetError">
<Description>
Creates and returns an object with the IsError flag set.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Message:%String="",Status:%Status="",RelatedId:%String=""</FormalSpec>
<ReturnType>Strix.Background.ItemInfo</ReturnType>
<Implementation><![CDATA[
	Set Me = ..%New()
	Set Me.IsError = 1
	Set Me.Message = Message
	Set Me.Status = Status
	Set Me.RelatedId = RelatedId
	Quit Me
]]></Implementation>
</Method>

<Method name="GetErrorText">
<Description>
Returns message and/or status, depending on which have a value</Description>
<FormalSpec>Language:%String="nl"</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Text = ..Message
	If ..Status = "" Quit Text
	
	If $length(Language) > 2 Set Language = $ZConvert($Extract(Language, 1, 2), "l")
	
	If Text '= "" Set Text = Text_": "
	Set Text = Text_": "_$System.Status.GetErrorText(..Status, Language)
	
	Quit Text
]]></Implementation>
</Method>

<Storage name="Default">
<Type>%Library.CacheSerialState</Type>
<State>ItemInfoState</State>
<StreamLocation>^Strix.Background.ItemInfoS</StreamLocation>
<Data name="ItemInfoState">
<Value name="1">
<Value>IsError</Value>
</Value>
<Value name="2">
<Value>Message</Value>
</Value>
<Value name="3">
<Value>Status</Value>
</Value>
<Value name="4">
<Value>RelatedId</Value>
</Value>
</Data>
</Storage>
</Class>
</Export>
