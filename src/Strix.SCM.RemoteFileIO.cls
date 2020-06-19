/// Export/import code
Class Strix.SCM.RemoteFileIO Extends Strix.SCM.FileIO
{

/// Exports an item, running post-processors if configured.
Method ExportItem(Output Filename As %String, Output Action As %Integer, Output Target As %String) As %Status
{
	If ..Handler.FileHandler = "" Set Status = $$$BuildStatus("FileHandler not configured.") Quit ""
	
	If '..Project.ExportUDL {
		Quit $$$BuildStatus("XML export not implemented for remote site.")
	}
	
	Set Filename = ..Project.GetExportFilename(..Item,,,.sc)
	If 'sc Quit sc
	
	Set Action = 3
	Set Target = ..GetIOCommand("GET", ..Item, Filename)
	
	Quit $$$OK
}

/// Exports data for a class to disk
Method ExportClassData(Output Filename As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Method LoadItem(Output Filename As %String, Output Action As %Integer, Output Target As %String) As %Status
{
	If ..Handler.FileHandler = "" Set Status = $$$BuildStatus("FileHandler not configured.") Quit ""
	
	If '..Project.ExportUDL {
		Quit $$$BuildStatus("XML import not implemented for remote site.")
	}
	
	Set Filename = ..Project.GetExportFilename(..Item,,,.sc)
	If 'sc Quit sc
	
	Set Action = 3
	Set Target = ..GetIOCommand("PUT", ..Item, Filename)
	
	Quit $$$OK
}

/// Loads data for a class from disk
Method LoadClassData(Output Filename As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Exports an entire project to disk
Method ExportProject(Quiet As %Boolean = 0) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Loads all project members form the configured directory
Method ImportProject(Quiet As %Boolean = 0) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

// =====

/// Performs item I/O using the remote file transfer helper.
Method GetIOCommand(Command As %String, Item As %String, Filename As %String) As %String
{
	Set Executable = $Replace(..Handler.FileHandler, "/", "\")
	If Executable [ " " Set Executable = $$$Quote(Executable)
	
	Set Url = ..GetServerUrl(Item)
	If Command = "PUT" Set Url = Url_"?ignoreConflict=1"
	
	; Create basic authentication string from Studio login credentials
	Set Creds = $ListToString(..Handler.Credentials, ":")
	If Creds = "" Set Creds = ":"
	Set Creds = $System.Encryption.Base64Encode(Creds)
	
	Set Command = $$$BuildStr("{} {} {} {} {}", Executable, Command, Url, $$$Quote(Filename), Creds)
	
	Quit Command
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

