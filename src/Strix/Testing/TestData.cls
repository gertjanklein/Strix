/// Helper code for retrieving existing Ensemble data (responses,
/// lookup tables) and storing it in XData blocks for use in tests.
/// 
/// This class is self-contained, so it can easily be copied to
/// another IRIS instance, to collect data there.
/// 
/// Includes both terminal and web interfaces.
Class Strix.Testing.TestData Extends %CSP.Page
{

/// Copies all messages in a given session. Can optionally exclude
/// requests or responses.
/// Do ##class(Strix.Testing.TestData).CopySession("","")
ClassMethod CopySession(SessionId As %String, ClassName As %String = "", Requests As %Boolean = 1, Responses As %Boolean = 1)
{
	; Default classname if none provided
	If ClassName = "" Set ClassName = "TestData.S"_SessionId
	
	; Create/open class definition
	#dim Class As %Dictionary.ClassDefinition
	If '..GetClass(ClassName, .Class) Return 0
	Set IsNew = Class.%Id() = ""
	
	Set Class.Description = "Data for Ensemble session id "_SessionId_$$$EOL_
	  "Recorded at system "_##class(%SYS.System).GetNodeName()_
	  ", instance "_##class(%SYS.System).GetInstanceName()_
	  ", namespace "_$ZUtil(5)_"."
	
	Set Query = "SELECT ID FROM Ens.MessageHeader WHERE SessionId = ?"
	Set Query = Query_" AND Type IN (1, 2) AND NOT MessageBodyClassName IS NULL"
	Set Query = Query_" ORDER BY MessageBodyId"
	
	#dim rs As %SQL.StatementResult
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, SessionId)
	While rs.%Next(.sc) {
		Set Hdr = ##class(Ens.MessageHeader).%OpenId(rs.ID, , .sc)
		If 'sc Return ..HandleError("Error opening Ensemble message header with id {}:", sc, rs.ID)
		Set Type = $Case(Hdr.Type, 1: "Request", 2: "Response")
		
		; Skip messages no longer present (possibly purged)
		Set Id = Hdr.MessageBodyId
		If '##class(Ens.MessageBody).%ExistsId(Id) {
			Do ..Report("Skipping {} message {}: body no longer present.", Hdr.MessageBodyClassName, Id)
			Continue
		}
		
		; Open message object
		Set Msg = ##class(Ens.MessageBody).%OpenId(Id, , .sc)
		If 'sc Return ..HandleError("Error opening Ensemble message with id {}:", sc, Id)
		
		; Show what's happening
		Do ..Report("{} {} {}", Type, Msg.%ClassName(), Id)
		
		; XData name is last part of classname plus sequence number of message type
		Set Count = $Increment(Counts(Msg.%ClassName(0)))
		Set XDataName = Msg.%ClassName(0)_$Select(Count=1: "", 1: Count)
		
		; Get/create XData
		#dim XData As %Dictionary.XDataDefinition
		Set XData = ..GetInCollection(Class.XDatas, XDataName, 1, .sc)
		If 'sc Return ..HandleError("Error getting XData {}/{}:", sc, ClassName, XDataName)
		If IsNew Set XData.SequenceNumber = $Increment(IsNew)
		
		; Clear stream in case it already existed
		Set sc = XData.Data.Clear()
		If 'sc Return ..HandleError("Error clearing existing XData {}/{}:", sc, ClassName, XDataName)
		
		; Export to XData block
		Set sc = Msg.XMLExportToStream(XData.Data,,",indent()")
		If 'sc Return ..HandleError("Error exporting message to XData {}/{}:", sc, ClassName, XDataName)
		
		Set XData.Description = Type_" "_Hdr.MessageBodyClassName_", header ids "_Hdr.%Id()_
		  "/"_Hdr.CorrespondingMessageId_$$$EOL_
		  "From """_Hdr.SourceConfigName_""" to """_Hdr.TargetConfigName_"""."
		
	}
	If 'sc Return ..HandleError("Error creating/iterating resultset:", sc)
	
	; Actually copied something?
	If $IsObject(Class) {
		; Save updated class
		Set sc = Class.%Save()
		If 'sc Return ..HandleError("Error saving updated dictionary for {}:", sc, ClassName)
		Do ..Report("Done.")
	
	} Else {
		Do ..Report("Nothing found to copy.")
		
	}
	
	Return ""
}

/// Saves the Ensemble message body of a request/response class to an XData block.
/// Do ##class(Strix.Testing.TestData).CopyMessage("","","")
ClassMethod CopyMessage(MessageId As %String, ClassName As %String = "", XDataName As %String = "") As %String
{
	; Open the Ensemble message
	Set Msg = ##class(Ens.MessageBody).%OpenId(MessageId, , .sc)
	If 'sc Return ..HandleError("Error opening Ensemble message with id {}:", sc, MessageId)
	
	; Default name for class and XData in case none provided
	If ClassName = "" Set ClassName = "TestData.M"_MessageId
	If XDataName = "" Set XDataName = Msg.%ClassName(0)_MessageId
	
	; Open/create the class to save the XData to
	If '..GetClass(ClassName, .Class) Return 0
	
	#dim XData As %Dictionary.XDataDefinition
	Set XData = ..GetInCollection(Class.XDatas, XDataName, 1, .sc)
	If 'sc Return ..HandleError("Error getting XData {}/{}:", sc, ClassName, XDataName)
	
	; Clear stream in case it already existed
	Set sc = XData.Data.Clear()
	If 'sc Return ..HandleError("Error clearing existing XData {}/{}:", sc, ClassName, XDataName)
	
	; Export to XData block
	Set sc = Msg.XMLExportToStream(XData.Data,,",indent()")
	If 'sc Return ..HandleError("Error exporting message to XData {}/{}:", sc, ClassName, XDataName)
	
	; Save updated class
	Set sc = Class.%Save()
	If 'sc Return ..HandleError("Error saving updated dictionary for {}:", sc, ClassName)
	
	Do ..Report("Done.")
	
	Return ""
}

/// Copies the contents of one or more lookup tables to XData block(s)
/// in the specified class. Table names are separated by a comma.
/// Do ##class(Strix.Testing.TestData).CopyLUT("","")
ClassMethod CopyLUT(Tables As %String, ClassName As %String = "") As %String
{
	; Default classname if none provided
	If ClassName = "" Set ClassName = "TestData.LUT"
	
	If '..GetClass(ClassName, .Class) Return ""
	
	For i = 1:1:$Length(Tables, ",") {
		Set Table = $ZStrip($Piece(Tables, ",", i), "<>WC")
		
		#dim XData As %Dictionary.XDataDefinition
		Set XData = ..GetInCollection(Class.XDatas, Table, 1, .sc)
		If 'sc Return ..HandleError("Error getting XData for {}/{}:", sc, ClassName, Table)
		
		; Clear stream in case it already existed
		Set sc = XData.Data.Clear()
		If 'sc Return ..HandleError("Error clearing existing XData {}/{}:", sc, ClassName, Table)
		
		Set sc = ##class(Ens.Util.LookupTable).%Export(XData.Data, Table)
		If 'sc Return ..HandleError("Error exporting data to {}/{}:", sc, ClassName, Table)
	}
	
	Set sc = Class.%Save()
	If 'sc Return ..HandleError("Error saving updated dictionary for {}:", sc, ClassName)
	
	Do ..Report("Done.")
	
	Return ""
}

// ===== Internal helpers =====

/// Opens or creates a class definition
ClassMethod GetClass(ClassName As %String, Output Class As %Dictionary.ClassDefinition) As %Boolean [ Private ]
{
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ClassName) {
		Set Class = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .sc)
		If 'sc Return ..HandleError("Error opening dictionary for {}:", sc, ClassName)
		
	} Else {
		Set Class = ##class(%Dictionary.ClassDefinition).%New(ClassName, 25)
		Set Class.Abstract = 1
		
	}
	
	Return 1
}

/// Returns an item, specified by name, from a relationship collection
/// (such as CompiledClass:Properties, etc.).
ClassMethod GetInCollection(Collection As %RelationshipObject, Name As %String, Create As %Boolean = 0, Output Status As %Status) As %RegisteredObject
{
	Set Status = $$$OK
	
	Set Found = 0
	Set Key = ""
	For  {
		Set Object = Collection.GetNext(.Key)
		If Key = "" Quit
		If Object.Name = Name Set Found = 1 Quit
	}
	If Found Quit Object
	
	If 'Create Quit ""
	
	Set Object = $ZObjClassMethod(Collection.ElementType, "%New")
	Set Object.Name = Name
	Set Status = Collection.Insert(Object)
	
	Quit Object
}

/// Displays an error message and/or %Status. Returns an arbitrary
/// (but false) value so this method can be used in a quit/return
/// expression.
ClassMethod HandleError(Message As %String = "", Status As %Status = "", Args... As %String) As %Boolean [ PublicList = Msgs ]
{
	Set Message = ..BuildMsg(Message, Status, Args...)
	
	; In CSP context, add error message to Msgs list
	If $IsObject($Get(%request)) {
		Set Msgs($i(Msgs)) = ..BuildMsg(Message, Status, Args...)
		Return 1
	}
	
	; In terminal context, write out the error message
	Write Message,!
	
	Return ""
}

/// Create a message from a template string, replacements, and %Status
ClassMethod BuildMsg(Message As %String = "", Status As %Status = "", Args... As %String) As %String
{
	; Replace message template placeholders, if any
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), , 1)
	}
	
	If Message '= "", Status '= "", 'Status {
		Quit Message_": "_$System.Status.GetErrorText(Status)
	}
	
	If Status '= "", 'Status {
		Set Message =  $System.Status.GetErrorText(Status)
	}
	
	Quit Message
}

/// Write progress message to terminal, if not in CSP context
ClassMethod Report(Message As %String = "", Args... As %String)
{
	If $IsObject($Get(%request)) Quit
	
	; Replace message template placeholders, if any
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), , 1)
	}
	Write Message,!
	
	Quit
}

// ===== CSP code =====

ClassMethod OnPage() As %Status [ PublicList = (Stream, Msgs), ServerOnly = 1 ]
{
	#dim %request As %CSP.Request
	
	; If we're downloading, just output the stream
	If %request.Method = "POST", $IsObject(Stream) {
		Do Stream.OutputToDevice()
		Quit $$$OK
	}
	
	; Get input values or defaults
	Set SessionId = %request.Get("session-id")
	Set ClassName = %request.Get("classname")
	Set LUT = %request.Get("lut")
	Set TakeRequests = ''%request.Get("requests", 1)
	Set TakeResponses = ''%request.Get("responses", 1)
	
	
	&html<<!doctype html>
<html>
<head>
<title>Test data copier</title>
#(..CSS())#
#(..JavaScript())#
</head>
<body>
<section>
<h1>Test data copier</h1>

<p class="usage">
Copies all requests and/or responses of a given Ensemble session
to XData blocks in a class, and downloads that class. (The class
is deleted again after downloading.) Optionally adds lookup tables
as well.
</p>>
	
	; Display error messages, if any
	If Msgs {
		&html<<div id="errors" class="errors">>
		For i = 1:1:Msgs &html<  <div>#(..EscapeHTML(Msgs(i)))#</div>>
		&html<</div>>
	}
	
	&html<<form id="form" action="" method="POST">
<table>
  <tr>
    <th><label for="session-id">Session id:</label></th>
    <td><input type=text id="session-id" name="session-id" value="#(..EscapeHTML(SessionId))#"></td>
  </tr>
  <tr>
    <th><label for="classname">Class name:</label></th>
    <td><input type=text id="classname" name="classname" value="#(..EscapeHTML(ClassName))#"></td>
  </tr>
  <tr>
    <th><label for="requests">Store requests:</label></th>
    <td><input type="checkbox" id="requests" name="requests" value="1" #($Select(TakeRequests:"checked",1:""))#></td>
  </tr>
  <tr>
    <th><label for="responses">Store responses:</label></th>
    <td><input type="checkbox" id="responses" name="responses" value="1" #($Select(TakeResponses:"checked",1:""))#></td>
  </tr>
  <tr>
    <th><label for="lut">Lookup tables:</label></th>
    <td><input type=text id="lut" name="lut" value="#(..EscapeHTML(LUT))#"></td>
  </tr>
  <tr>
    <td colspan="2"><input type="submit" value="Collect" title="Collect the requested data"></td>
  </tr>
</table>
</form>

</section>
</body>
</html>>
	
	Quit $$$OK
}

ClassMethod OnPreHTTP() As %Boolean [ PublicList = (Stream, Msgs) ]
{
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	#define Err(%s) Set Msgs($i(Msgs))=%s
	
	Set Stream = "", Msgs = 0
	If %request.Method '= "POST" Quit 1
	
	; Get input values
	Set SessionId = $ZStrip(%request.Get("session-id"), "<>WC")
	Set ClassName = $ZStrip(%request.Get("classname"), "<>WC")
	Set LUT = $ZStrip(%request.Get("lut"), "<>WC")
	Set TakeRequests = ''%request.Get("requests")
	Set TakeResponses = ''%request.Get("responses")
	
	; Some basic validity checks
	If SessionId = "" {
		$$$Err("No session id specified.")
	} ElseIf SessionId '? 1.N {
		$$$Err("Session id should be numeric.")
	} Else {
		Do ..CheckSessionId(SessionId, .Msgs)
	}
	If ClassName = "" {
		$$$Err("No class name specified.")
	} ElseIf '$ZName(ClassName, 4) {
		$$$Err("Invalid class name '"_ClassName_"'.")
	}
	If 'TakeRequests, 'TakeResponses, LUT = "" {
		$$$Err("At least one of requests, responses or lookup tables should be specified.")
	}
	If Msgs Quit 1
	
	
	; Create class with request/response data
	Set Result = ..CopySession(SessionId, ClassName, TakeRequests, TakeResponses)
	If Result = 0 Quit $$$OK
	
	; Add lookup tables, if so requested
	If LUT '= "" {
		Set Result = ..CopyLUT(LUT, ClassName)
		If Result = 0 Quit $$$OK
	}
	
	; Export the class as XML
	Set sc = $System.OBJ.ExportToStream(ClassName_".cls", .Stream, "-d")
	If 'sc $$$Err($System.Status.GetErrorText(sc)) Quit 1
	
	; Set up response to download the export
	Set %response.ContentType = "application/xml"
	Do %response.SetHeader("Content-Disposition", "attachment; filename="""_ClassName_".cls.xml""")
	
	; Delete the class
	Do ##class(%Dictionary.ClassDefinition).%DeleteId(ClassName)
	
	
	Quit 1
}

/// Check whether the passed in id is a valid session id
ClassMethod CheckSessionId(SessionId As %String, ByRef Msgs)
{
	#def1arg Err(%s) Set Msgs($i(Msgs))=..BuildMsg(%s)
	
	; First check whether the session exists
	Set Query = "SELECT TOP 1 ID FROM Ens.MessageHeader WHERE SessionId = ?"
	Set Query = Query_" AND NOT MessageBodyClassName IS NULL"
	#dim rs As %SQL.StatementResult
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, SessionId)
	; Exists? Done.
	If rs.%Next(.sc) Quit
	
	; Error checking? Report.
	If 'sc $$$Err("Error checking session {}:", sc, SessionId) Quit
	
	; Check if this is actually a message header id
	Set Query = "SELECT SessionId FROM Ens.MessageHeader WHERE ID = ?"
	Set Query = Query_" AND NOT MessageBodyClassName IS NULL"
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, SessionId)
	If 'rs.%Next(.sc) || (rs.SessionId = "") {
		$$$Err("Session with id {} not found.", sc, SessionId)
		Quit
	}
	
	; Found; suggest the actual session in the error message
	$$$Err("Session with id {} not found. Did you mean session {}?",, SessionId, rs.SessionId)
	
	Quit
}

ClassMethod CSS()
{
	&html<<style>
body {
  font-family: system-ui, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", "Liberation Sans", sans-serif;
  margin: 0;
  padding: 0;
  background-color: #f0f0f0;
}
section {
  max-width: 50em;
  margin: 0 auto 0 auto;
  background-color: white;
}
h1 {
  margin-top: 0;
  padding: 0.3em 0.5em;
  border-radius: 8px;
  text-align: center;
  background-color: #57a;
  color: #eee;
}
 
.usage {
  padding: 0 2em;
}
 
form {
  padding: 0 1em;
}
table {
  border-collapse: collapse;
  border-spacing: 1em 0;
  width: 100%;
 
}
td, th {
  border-top: 1px solid #ccc;
  border-bottom: 1px solid #ccc;
  padding: 0.6em 0.2em 0.6em 0.5em;
  vertical-align: baseline;
}
th {
  font-weight: normal;
  text-align: left;
  width: 10%;
  white-space: nowrap;
}
 
#session-id {
  width: 10em;
}
#classname {
  width: 25em;
}
#lut {
  width: 100%;
  box-sizing: border-box;
}
 
div.errors {
  margin: 1em;
  font-weight: bold;
  color: red;
}
</style>>
	
	Quit ""
}

ClassMethod JavaScript()
{
	&html<<script type="text/javascript">
function setup() {
	// Clear error messages on submit
	document.getElementById("form").addEventListener("submit", (event) => {
		let el = document.getElementById("errors");
		if (el) el.parentElement.removeChild(el);
	});
	
	// Create default for classname when session id entered
	document.getElementById("session-id").addEventListener("blur", (event) => {
		let el = document.getElementById("classname");
		if (!el.value && event.target.value) {
			el.value = "TestData.S" + event.target.value;
		}
	});
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", setup);
} else {
  setup();
}
</script>>
	
	Quit ""
}

}
