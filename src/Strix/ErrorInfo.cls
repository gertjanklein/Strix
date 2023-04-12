Include %occErrors

Class Strix.ErrorInfo Extends %RegisteredObject
{

/// Returns as much info about a fault as possible. Expected to be called from
/// an error trap, as SOAP faults are thrown. An optional status can be passed
/// in if known, but is only used if no fault is known.
ClassMethod ParseSOAPError(Fault As %SOAP.Fault = "", Status As %Status = {$Get(%objlasterror)}, AsStatus As %Boolean = 0, Language As %String = "en") As %String
{
	If $IsObject(Fault) {
		;Data may be XML-escaped; attempt an un-escape
		Try { Set ErrorMsg = $ZConvert(Fault.detail, "I", "XML") }
		Catch e { Set ErrorMsg = $ZConvert(ErrorMsg, "&apos;", "'") }
		
		;Some error details contain an XML fragment; extract the interesting part
		If ErrorMsg [ "<text>" {
			Set ErrorMsg = $Piece(ErrorMsg, "<text>", 2)
			Set ErrorMsg = $Piece(ErrorMsg, "</text>", 1)
		}
		
		;Text may contain lf-only newlines; make sure everything is crlf
		Set ErrorMsg = $Translate(ErrorMsg, $Char(13), "")
		Set ErrorMsg = $Replace(ErrorMsg, $Char(10), $Char(13, 10))
		
		;Prefix with faultstring
		Set ErrorMsg = "["_Fault.faultstring_"] "_ErrorMsg
		
		If AsStatus Quit $$$ERROR($$$GeneralError, ErrorMsg)
		
		Quit ErrorMsg
	}
	
	If AsStatus {
		If Status '= "", 'Status Quit Status
		;No fault, no error status...
		Quit $$$ERROR($$$GeneralError, $ZError)
	}
	
	;Fallback: parse status
	If 'Status, $System.Status.Equals(Status, $$$SOAPFaultReceived) {
		Set ErrorMsg = $System.Status.GetErrorText(Status, Language)
		Set ErrorMsg = $Piece(ErrorMsg, "detail=", 2)
		
		;Data may be XML-escaped; attempt an un-escape
		Try { Set ErrorMsg = $ZConvert(ErrorMsg, "I", "XML") }
		Catch e { Set ErrorMsg = $ZConvert(ErrorMsg, "&apos;", "'") }
		
	} ElseIf Status '= "" {
		
		Set ErrorMsg = $System.Status.GetErrorText(Status, Language)
		
	} Else {
		Set ErrorMsg = $ZError
		
	}
	
	Quit ErrorMsg
}

}

