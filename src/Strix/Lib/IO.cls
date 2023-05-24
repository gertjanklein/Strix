Include Strix

Class Strix.Lib.IO Extends %RegisteredObject
{

/// Creates a pipe to the specified OS command. If an error occurs opening
/// or reading the pipe, a message is placed in output parameter ErrorMsg.
/// If Strip is true, leading and trailing whitespace is removed from the
/// result.
ClassMethod GetCommandOutput(Command As %String, Strip As %Boolean = 1, Directory As %String = "", Output ErrorMsg As %String, Timeout As %Float = 30) As %String
{
	Set $ZTrap = "Error"
	
	Set IO = $IO, ErrorMsg = "", Output = ""
	
	; Attempt to change directory if requested, saving the current directory
	If Directory '= "" Set PrevDir = ##class(%SYSTEM.Process).CurrentDirectory(Directory)
	
	; Use a so-called command pipe to avoid the maximum length of 256 for
	; standard pipe commands.
	Set Pipe = "|CPIPE|"_$Job
	
	; Open the pipe
	Open Pipe:(Command:"QRU"):15
	If $Test {
		; A command may not return any data at all; this by default results
		; in an <ENDOFFILE> error. Prevent this by setting a flag:
		Set PrevZEOF = $System.Process.SetZEOF(1)
		
		; Get the pipe data
		Use Pipe
		Read Output#$$$MaxStringLength:Timeout
		If $Test {
			; Success; get exit code if available
			Set ExitCode = ..PipeExitCode(Pipe, .sc)
			If ExitCode '= "", ExitCode '= 0 Set ErrorMsg = $$$BuildMsg("Error code {} from command.", ExitCode)
			
		} Else {
			; Timed out
			Set ErrorMsg = "Error: timeout occurred reading pipe."
			
		}
		
		; Restore state
		Use IO
		Close Pipe
		If PrevZEOF = 0 Do $System.Process.SetZEOF(PrevZEOF)
		
	} Else {
		Set ErrorMsg = "Error: timeout occurred opening pipe."
		
	}
	
	; Restore directory
	If Directory '= "" Do ##class(%SYSTEM.Process).CurrentDirectory(PrevDir)
	
	; Strip whitespace if so requested
	If Strip Set Output = $ZStrip(Output, "<>WC")
	
	Quit Output
	
	
Error
	Set $ZTrap = ""
	Set ErrorMsg = "Error trapped: "_$ZError
	Use IO
	Try { Close Pipe } Catch e {}
	If $Data(PrevZEOF) Do $System.Process.SetZEOF(PrevZEOF)
	If $Data(PrevDir) Do ##class(%SYSTEM.Process).CurrentDirectory(PrevDir)
	Quit ""
}

/// Retrieve exit code for pipe, if available.
ClassMethod PipeExitCode(Pipe As %String, Output Status As %Status) As %Integer
{
#if ##expression(##class(%Dictionary.MethodDefinition).%ExistsId("%SYSTEM.Process|PipeExitCode"))
	Set ExitCode = $SYSTEM.Process.PipeExitCode(Pipe, .Status)
	Quit ExitCode
	
#else
	Set Status = $$$BuildStatus("Retrieving exit code unavailable on this system.")
	Quit ""
	
#endif
}

}
