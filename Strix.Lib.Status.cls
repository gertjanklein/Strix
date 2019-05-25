Include %occErrors

Class Strix.Lib.Status Extends %RegisteredObject
{

/// Builds a %Status from the combined input. Message is converted to
/// a GeneralError %Status; if Status is passed-in, it is appended to
/// it. Intended usage is to prefix extra information to an error status
/// returned from a system call, through the $$$BuildStatus macro.
ClassMethod BuildStatus(Message As %String, Status As %Status = "", Args... As %String) As %Status
{
	;Replace placeholders with content, if present
	If $Get(Args) Set Message = ##class(Strix.Lib.String).TemplateReplace(Message, Args...)
	
	;Convert message to %Status
	Set MsgStatus = $System.Status.Error($$$GeneralError, Message)
	
	;Append status from parameter, if specified
	If Status '= "" Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	
	Quit MsgStatus
}

}

