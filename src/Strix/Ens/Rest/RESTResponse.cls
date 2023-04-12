Class Strix.Ens.Rest.RESTResponse Extends Ens.Response
{

/// HTTP status to return. Just the numeric code part (e.g. "200");
/// the textual part will be added by the CSP code.
Property Status As %String;

/// Content-Type to return; if empty, the REST service determines it.
Property ContentType As %String(MAXLEN = 256);

/// Character encoding to return; if empty, the REST service determines it.
Property CharSet As %String;

/// Additional HTTP headers to return
Property Headers As array Of %String(MAXLEN = 8192, XMLITEMNAME = "Value", XMLKEYNAME = "Name");

/// The data to return, if any
Property Payload As %Stream.GlobalCharacter;

/// URL to redirect to
Property Redirect As %String;

/// Server side redirection URL
Property ServerSideRedirect As %String;

// =====

Storage Default
{
<Data name="CSPResponseDefaultData">
<Subscript>"CSPResponse"</Subscript>
<Value name="1">
<Value>Status</Value>
</Value>
<Value name="2">
<Value>ContentType</Value>
</Value>
<Value name="3">
<Value>Payload</Value>
</Value>
<Value name="4">
<Value>Redirect</Value>
</Value>
<Value name="5">
<Value>ServerSideRedirect</Value>
</Value>
<Value name="6">
<Value>CharSet</Value>
</Value>
</Data>
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"Strix.Ens.Rest.RESTResponse.Headers"</Subscript>
</Data>
<DefaultData>CSPResponseDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}
