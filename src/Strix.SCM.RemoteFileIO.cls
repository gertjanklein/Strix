/// Export/import code
Class Strix.SCM.RemoteFileIO Extends Strix.SCM.FileIO
{

/// Loads all project members form the configured directory.
/// This is unimplemented in remote configuration.
Method ImportProject(Quiet As %Boolean = 0) As %Status
{
	Quit $$$BuildStatus(, $$$NotImplemented)
}

/// Exports an item, running post-processors if configured.
Method Export(Item As %String, AsUDL As %Boolean, Processors As %ListOfObjects, Filename As %String) As %Status
{
	If AsUDL = 0 {
		Quit $$$BuildStatus("XML export not implemented for remote site.")
	}
	
	Set Dir = ##class(%File).GetDirectory(..Handler.FileHandler)
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(..Handler.FileHandler)
	
	Set Url = ..GetServerUrl(Item)
	
	; Create basic authentication string from Studio login credentials
	Set Creds = $ListToString(..Handler.Credentials, ":")
	If Creds = "" Set Creds = ":"
	Set Creds = $System.Encryption.Base64Encode(Creds)
	
	Set Command = $$$BuildStr("{} GET {} {} {}", Executable, Url, $$$Quote(Filename), Creds)
	;Write !,Command
	
	; Get output and determine if there's an error
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , Dir, .ErrorMsg)
	If ErrorMsg '= "" Quit $$$BuildStatus("Error exporting item: {}",, ErrorMsg)
	If $Match(Result, "^(Error|Usage).*") {
		Quit $$$BuildStatus("Error exporting item; local program returned: {}",, Result)
	}
	;Write !,">>> "_Result
	
	Quit $$$OK
}

Method Import(Filename As %String, Item As %String, Flags As %String = "ck-d") As %Status
{
	;Normalize name:
	$$$NormalizeType(Item)
	
	Set Dir = ##class(%File).GetDirectory(..Handler.FileHandler)
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(..Handler.FileHandler)
	
	Set Url = ..GetServerUrl(Item)_"?ignoreConflict=1"
	
	; Create basic authentication string from Studio login credentials
	Set Creds = $ListToString(..Handler.Credentials, ":")
	If Creds = "" Set Creds = ":"
	Set Creds = $System.Encryption.Base64Encode(Creds)
	
	Set Command = $$$BuildStr("{} PUT {} {} {}", Executable, Url, $$$Quote(Filename), Creds)
	;Write !,Command
	
	; Get output and determine if there's an error
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , Dir, .ErrorMsg)
	If ErrorMsg '= "" Quit $$$BuildStatus("Error loading item: {}",, ErrorMsg)
	If $Match(Result, "^(Error|Usage).*") {
		Quit $$$BuildStatus("Error loading item; local program returned: {}",, Result)
	}
	;Write !,">>> "_Result
	
	If $Piece(Flags, "/") [ "c", $$$NormalizedType(Item) = "cls" {
		Set sc = $System.OBJ.Compile($$$ItemName(Item), Flags)
		If 'sc Quit $$$BuildStatus("Error compiling {}:", sc, Item)
	}
	
	Quit $$$OK
}

/// Returns the server URL for the current Studio connection.
/// If an item is specified, amends the URL with the path to
/// the atelier API document path for that item.
ClassMethod GetServerUrl(Item As %String) As %String
{
	Try {
		Set Host = $SYSTEM.TCPDevice.LocalAddr()
	} Catch (e) {
		Set Host = ##class(%Function).HostName()
	}
	Set Port = $Get(^%SYS("WebServer","Port"), "57772")
	
	Set Url = "http://"_Host_":"_Port
	If Item '= "" Set Url = Url_"/api/atelier/v1/"_$ZUtil(5)_"/doc/"_Item
	
	Quit Url
}

}

