/// Generic request from a REST service. Contains
/// %CSP.Request properties.
Class Strix.Ens.Rest.RESTRequest Extends Ens.Request
{

/// The name of the REST method this request originated from
Property MethodName As %String;

/// Parameters passed to the REST method, parsed from the URL
Property MethodParameters As array Of %String(MAXLEN = "", XMLITEMNAME = "Value", XMLKEYNAME = "Name");

// -----

/// Parameters as parsed by the CSP engine
Property Parameters As array Of %List(XMLITEMNAME = "Values", XMLKEYNAME = "Name");

/// The body of the request as a stream
Property Payload As %GlobalBinaryStream;

/// The path part of the URL the service was called with
Property URL As %String(MAXLEN = "");

/// Content-Type header, if present
Property ContentType As %String;

/// Charset, if specified
Property CharSet As %String;

/// Whether HTTPS was used
Property Secure As %Boolean;

/// CGI environment variables
Property CgiEnv As array Of %String(MAXLEN = "", XMLITEMNAME = "Value", XMLKEYNAME = "Name");

// =====

/// Mimick %CSP.Request's Get method
Method Get(ParameterName As %String, Default As %String = "", Index As %Integer = 1) As %String
{
	If '..Parameters.IsDefined(ParameterName) Quit Default
	Set Values = ..Parameters.GetAt(ParameterName)
	If '$ListData(Values, Index) Quit Default
	Quit $List(Values, Index)
}

/// Returns all (0..n) parameter values, stored as a %List, as a %ListOfDataTypes
Method GetList(ParameterName As %String) As %ListOfDataTypes
{
	Set Values = ..Parameters.GetAt(ParameterName)
	Set Result = ##class(%ListOfDataTypes).%New()
	For i = 1:1:$ListLength(Values) Do Result.Insert($ListGet(Values, i))
	Quit Result
}

// =====

Storage Default
{
<Data name="CSPRequestDefaultData">
<Subscript>"CSPRequest"</Subscript>
<Value name="1">
<Value>MethodName</Value>
</Value>
<Value name="2">
<Value>Payload</Value>
</Value>
<Value name="3">
<Value>URL</Value>
</Value>
<Value name="4">
<Value>ContentType</Value>
</Value>
<Value name="5">
<Value>CharSet</Value>
</Value>
<Value name="6">
<Value>Secure</Value>
</Value>
</Data>
<Data name="CgiEnv">
<Attribute>CgiEnv</Attribute>
<Structure>subnode</Structure>
<Subscript>"Strix.Ens.Rest.RESTRequest.CgiEnv"</Subscript>
</Data>
<Data name="MethodParameters">
<Attribute>MethodParameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"Strix.Ens.Rest.RESTRequest.MethodParameters"</Subscript>
</Data>
<Data name="Parameters">
<Attribute>Parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"Strix.Ens.Rest.RESTRequest.Parameters"</Subscript>
</Data>
<DefaultData>CSPRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}
