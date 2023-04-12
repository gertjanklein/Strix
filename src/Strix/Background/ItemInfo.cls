/// This class describes the results of a single item handled in a job
/// (i.e., by a subclass of the Job class).
Class Strix.Background.ItemInfo Extends (%SerialObject, %XML.Adaptor)
{

/// Whether this item describes an error
Property IsError As %Boolean;

/// Textual description
Property Message As %String(MAXLEN = "");

/// If available, a %Status with error information
Property Status As %Status;

/// If this item describes a specific object, it's id
Property RelatedId As %String(MAXLEN = "");

/// Creates and returns an object with the IsError flag set.
ClassMethod GetError(Message As %String = "", Status As %Status = "", RelatedId As %String = "") As Strix.Background.ItemInfo
{
	Set Me = ..%New()
	Set Me.IsError = 1
	Set Me.Message = Message
	Set Me.Status = Status
	Set Me.RelatedId = RelatedId
	Quit Me
}

/// Returns message and/or status, depending on which have a value
Method GetErrorText(Language As %String = "nl") As %String
{
	Set Text = ..Message
	If ..Status = "" Quit Text
	
	If $length(Language) > 2 Set Language = $ZConvert($Extract(Language, 1, 2), "l")
	
	If Text '= "" Set Text = Text_": "
	Set Text = Text_": "_$System.Status.GetErrorText(..Status, Language)
	
	Quit Text
}

Storage Default
{
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
<State>ItemInfoState</State>
<StreamLocation>^Strix.Background.ItemInfoS</StreamLocation>
<Type>%Library.CacheSerialState</Type>
}

}
