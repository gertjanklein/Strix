Class Strix.Lib.IO Extends %RegisteredObject
{

/// Creates a pipe to the specified OS command. If an error occurs opening
/// or reading the pipe, a message is placed in output parameter ErrorMsg.
/// If Strip is true, leading and trailing whitespace is removed from the
/// result.
ClassMethod GetCommandOutput(Command As %String, Strip As %Boolean = 1, ChangeDir As %Boolean = 0, Output ErrorMsg As %String) As %String
{
	Set $ZTrap = "Error"
	
	Set IO = $IO
	Set ErrorMsg = ""
	
	If ChangeDir {
		; Attempt to change directory to the command location, saving
		; the current directory
		Set Dir = ##class(%File).GetDirectory($Piece(Command, " "))
		Set Dir = ##class(%SYSTEM.Process).CurrentDirectory(Dir)
	}
	
	; Use a so-called command pipe to avoid the maximum length of 256 for
	; standard pipe commands.
	Set Pipe = "|CPIPE|"_$Job
	
	; Open it
	Open Pipe:(Command:"QRU"):5
	If '$Test {
		Set ErrorMsg = "Error: timeout occurred opening pipe to "_Command
		If ChangeDir Do ##class(%SYSTEM.Process).CurrentDirectory(Dir)
		Quit ""
	}
	
	; A command may not return any data at all; this by default results
	; in an <ENDOFFILE> error. Prevent this by setting a flag:
	Set PrevZEOF = $System.Process.SetZEOF(1)
	
	; Get the pipe data
	Use Pipe
	Read Output:5
	Set Timedout = '$Test
	Use IO
	Close Pipe
	If ChangeDir Do ##class(%SYSTEM.Process).CurrentDirectory(Dir)
	
	; Restore previous setting of flag
	If PrevZEOF = 0 Do $System.Process.SetZEOF(PrevZEOF)
	
	If Timedout Set ErrorMsg = "Error: timeout occurred reading pipe "_Command Quit ""
	
	; Strip whitespace if so requested
	If Strip Set Output = $ZStrip(Output, "<>WC")
	
	Quit Output
	
	
Error
	Set $ZTrap = ""
	Set ErrorMsg = "Error trapped reading pipe: "_$ZError
	Use IO
	Try { Close Pipe } Catch e {}
	If $Data(PrevZEOF) Do $System.Process.SetZEOF(PrevZEOF)
	If ChangeDir Do ##class(%SYSTEM.Process).CurrentDirectory(Dir)
	Quit ""
}

}

