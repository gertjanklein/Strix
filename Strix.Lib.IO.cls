<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.IO">
<Super>%RegisteredObject</Super>
<TimeCreated>64307,60337.004726</TimeCreated>

<Method name="GetCommandOutput">
<Description>
Creates a pipe to the specified OS command. If an error occurs opening
or reading the pipe, a message is placed in output parameter ErrorMsg.
If Strip is true, leading and trailing whitespace is removed from the
result.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Command:%String,Strip:%Boolean=1,*ErrorMsg:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set $ZTrap = "Error"
	
	Set IO = $IO
	Set ErrorMsg = ""
	
	; Use a so-called command pipe to avoid the maximum length of 256 for
	; standard pipe commands.
	Set Pipe = "|CPIPE|"_$Job
	
	; Open it
	Open Pipe:(Command:"QRU"):5
	If '$Test Set ErrorMsg = "Error: timeout occurred opening pipe to "_Command Quit ""
	
	; A command may not return any data at all; this by default results
	; in an <ENDOFFILE> error. Prevent this by setting a flag:
	Set PrevZEOF = $System.Process.SetZEOF(1)
	
	; Get the pipe data
	Use Pipe
	Read Output:5
	Set Timedout = '$Test
	Use IO
	Close Pipe
	
	; Restore previous setting of flag
	If PrevZEOF = 0 Do $System.Process.SetZEOF(PrevZEOF)
	
	If Timedout Set ErrorMsg = "Error: timeout occurred reading pipe "_Command Quit ""
	
	; Strip whitespace if so requested
	If Strip Set Output = $ZStrip(Output, "<>WC")
	
	Quit Output
	
	
Error
	Set $ZTrap = ""
	Use IO
	Close Pipe
	If $Data(PrevZEOF) Do $System.Process.SetZEOF(PrevZEOF)
	Set ErrorMsg = "Error trapped reading pipe: "_$ZError
	Quit ""
]]></Implementation>
</Method>
</Class>
</Export>
