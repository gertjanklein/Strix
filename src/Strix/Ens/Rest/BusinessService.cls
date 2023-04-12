Class Strix.Ens.Rest.BusinessService Extends Ens.BusinessService
{

/// Helper method. Sends a request (synchroneously) to the specified
/// target. Adds information from the %request object to the Ensemble
/// Request object. Upon successful return, sets the %response
/// properties from the returned Response object.
Method SendRequest(Target As %String, Request As Strix.Ens.Rest.RESTRequest, Output Response As Strix.Ens.Rest.RESTResponse) As %Status
{
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	; Copy properties
	Set Request.URL = %request.URL
	Set Request.ContentType = %request.ContentType
	Set Request.CharSet = %request.CharSet
	Set Request.Secure = %request.Secure
	If $IsObject(%request.Content) {
		Set sc = Request.Payload.CopyFrom(%request.Content)
		If 'sc Quit sc
	}
	
	; HTTP query values. More than one value per name is possible. Store as
	; %List of values.
	Set Key = ""
	For {
		Set Key = $Order(%request.Data(Key))
		If Key = "" Quit
		
		Set Combined = ""
		Set Idx = ""
		For	 {
			Set Idx = $Order(%request.Data(Key, Idx), 1, Value)
			If Idx = "" Quit
			Set Combined = Combined_$ListBuild(Value)
		}
		
		Do Request.Parameters.SetAt(Combined, Key)
	}
	
	; CGI environment variables. Limit to those actually related to
	; the request.
	Set Key = ""
	For	 {
		Set Key = %request.NextCgiEnv(Key)
		If Key = "" Quit
		
		If Key '? 1"HTTP_"1.E,
			 Key '? 1"REQUEST_"1.E,
			 Key '? 1"SERVER_"1.E,
			 Key '= "REMOTE_ADDR" { Continue }
		Do Request.CgiEnv.SetAt(%request.GetCgiEnv(Key), Key)
	}
	
	
	; Send the request to the target
	Set sc = ..SendRequestSync(Target, Request, .Response)
	If 'sc Quit sc
	
	
	; == Copy the response properties to %response
	
	; Copy any HTTP headers to the response
	Set Key = ""
	For	 {
		Set Value = Response.Headers.GetNext(.Key)
		If Key = "" Quit
		Do %response.SetHeader(Key, Value)
	}
	
	; If we're to redirect elsewhere, the other properties don't apply
	If Response.Redirect '= "" {
		Set %response.Redirect = Response.Redirect
		Quit $$$OK
	}
	
	; Set HTTP status; support just specifying the numeric code
	Set Status = Response.Status
	If Status ? 1.N Set Status = ..StatusWithDesc(Status)
	Set %response.Status = Status
	
	; If we do a server-side redirect, we can't output contents
	If Response.ServerSideRedirect '= "" {
		Set %response.ServerSideRedirect = Response.ServerSideRedirect
		Quit $$$OK
	}
	
	; Set Content-Type and Charset
	If Response.ContentType '= "" Set %response.ContentType = Response.ContentType
	If Response.CharSet '= "" Set %response.CharSet = Response.CharSet
	
	; Finally, output the contents, if any
	If Response.Payload.Size {
		Do Response.Payload.OutputToDevice()
	}
	
	Quit $$$OK
}

/// Given a single HTTP status code (e.g. "200"), attempt to find the
/// full HTTP status line value (e.g. "200 OK") by scanning the parameters
/// in %CSP.REST that define such lines.
ClassMethod StatusWithDesc(StatusCode As %String) As %String
{
	Set Name = ""
	For	 {
		Set Name = $$$defMemberNext("%CSP.REST", $$$cCLASSparameter, Name)
		If Name = "" Quit
		If Name '? 1"HTTP"3N1.E Continue
		
		Set Value = $$$defMemberKeyGet("%CSP.REST", $$$cCLASSparameter, Name, $$$cPARAMdefault)
		If +Value = StatusCode Return Value
	}
	; Can't find the description, return unaltered.
	Quit StatusCode
}

}
