/// Superclass for mock business operations. Automatically populates
/// the source test location information in local properties, and
/// records incoming messages (in the runner's test data, under the
/// name "Calls".)
Class Strix.Testing.Ens.BusinessOperation Extends (Ens.BusinessOperation, Strix.Testing.EnsTestCase)
{

/// The source of the current test, in the form
/// classname:methodname
Property SrcTestLocation As %String [ Transient ];

/// The current test class
Property SrcTestClass As %String [ Transient ];

/// The package of the current test class
Property SrcTestPackage As %String [ Transient ];

/// The current test method
Property SrcTestMethod As %String [ Transient ];

/// Handler for Ensemble messages sent to this business operation.
/// Sets up the source test location, and records the incoming
/// call.
/// 
/// The source test location can be used to determine what to return here.
/// 
/// For the call, the message body class name is recorded; this can be used
/// to assert an expected call actually took place. Additionally, the id of
/// the request message header is recorded; this can be used to retrieve
/// other fields if needed, e.g. the message body id.
Method MessageHeaderHandler(RequestHeader As Ens.MessageHeader, Output ResponseHeader As Ens.MessageHeader) As %Status [ Internal ]
{
	; Session id has not yet been set on the BO, but is available from
	; the header object
	Set SessionId = RequestHeader.SessionId
	
	; Record test location information
	Set ..SrcTestLocation = ##class(Strix.Testing.Runner).GetSource(SessionId)
	Set ..SrcTestClass = $Piece(..SrcTestLocation, ":", 1)
	Set ..SrcTestPackage = $Piece(..SrcTestClass, ".", 1, *-1)
	Set ..SrcTestMethod = $Piece(..SrcTestLocation, ":", 2)
	
	; Record this call
	Set Calls = ##class(Strix.Testing.Runner).GetTestData(SessionId, "Calls")
	Set Call = $lb(RequestHeader.MessageBodyClassName, RequestHeader.MessageId())
	Do ##class(Strix.Testing.Runner).SetTestData(SessionId, "Calls", Calls_$lb(Call))
	
	Quit ##super(RequestHeader, .ResponseHeader)
}

}

