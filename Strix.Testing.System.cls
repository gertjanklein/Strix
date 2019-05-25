Include Strix

Class Strix.Testing.System Extends %RegisteredObject
{

// ----- Databases

ClassMethod CreateDatabase(Name As %String, BaseDir As %String = "", Output DatabaseDir As %String) As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	; --- Determine directory
	
	If BaseDir = "" Set BaseDir = $System.Util.ManagerDirectory()
	Set DatabaseDir = ##class(%File).SubDirectoryName(BaseDir, Name)
	If '##class(%File).DirectoryExists(DatabaseDir) {
		Set ok = ##class(%File).CreateDirectoryChain(DatabaseDir, .rc)
		If 'ok Quit ..BuildStatus("Error {} creating directory {}.",, rc, DatabaseDir)
	}
	
	; --- Create database file
	
	Set sc = ##class(SYS.Database).CreateDatabase(DatabaseDir, 10)
	If 'sc Quit ..BuildStatus("Error creating database file at {}:", sc, DatabaseDir)
	
	; --- Create database definition
	
	Set Properties("Directory") = DatabaseDir
	Set sc = ##class(Config.Databases).Create(Name, .Properties)
	If 'sc Quit ..BuildStatus("Error creating database definition for {}:", sc, DatabaseDir)
	
	Quit $$$OK
}

ClassMethod DeleteDatabase(Directory As %String) As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	; --- Get name from directory
	
	; Make sure the directory doesn't end in a slash
	Set Directory = ##class(%File).NormalizeFilename(Directory)
	
	; Determine the name of the database
	Set sc = ##class(Config.Databases).DatabasesByDirectory("", Directory, .dblist)
	If 'sc Quit ..BuildStatus("Error determining database(s) for directory {}:", sc, Directory)
	If dblist = "" Quit ..BuildStatus("No database found in directory {}:",, Directory)
	If $ListLength(dblist) > 1 Quit ..BuildStatus("Multiple databases present in {}: {}.",, Directory, $lts(dblist, ", "))
	Set Name = $List(dblist, 1)
	
	; --- Delete database definition
	
	Set sc = ##class(Config.Databases).Delete(Name)
	If 'sc {
		Set ec = $System.Status.GetErrorCodes(sc)
		If ec '= $$$DatabaseDefinitionDoesNotExist Quit ..BuildStatus("Error deleting database definition {}:", sc, Name)
	}
	
	; --- Delete database file
	
	Set sc = ##class(SYS.Database).DeleteDatabase(Directory)
	If 'sc {
		Set ec = $System.Status.GetErrorCodes(sc)
		If ec '= $$$DatabaseDoesNotExist Quit ..BuildStatus("Error deleting database file {}:", sc, Directory)
	}
	
	; --- Delete directory
	
	Set ok = ##class(%File).RemoveDirectoryTree(Directory)
	If 'ok Quit ..BuildStatus("Error removing database directory {}:", $g(%objlasterror), Directory)
	
	
	Quit $$$OK
}

// ----- Namespaces

ClassMethod CreateNamespace(Name As %String, DatabaseName As %String = "") As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	If DatabaseName = "" Set DatabaseName = Name
	Set Properties("Globals") = DatabaseName
	
	Set sc = ##class(Config.Namespaces).Create(Name, .Properties)
	If 'sc Quit ..BuildStatus("Error creating namespace {} for database {}:", sc, Name, DatabaseName)
	
	Quit $$$OK
}

ClassMethod DeleteNamespace(Name As %String) As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	Set sc = ##class(Config.Namespaces).Delete(Name)
	If 'sc Quit ..BuildStatus("Error deleting namespace {}:", sc, Name)
	
	Quit $$$OK
}

// ----- Ensemble

ClassMethod EnableEnsemble(Namespace As %String, NoExtraDbs As %Boolean = 1) As %Status
{
	If NoExtraDbs {
		; If a mapping for these globals exists, the secondary and temp databases
		; will not be created.
		Set sc = ..MapGlobal(Namespace, "Ens.SecondaryData*")
		If 'sc Quit sc
		Set sc = ..MapGlobal(Namespace, "CacheTemp.Ens*")
		If 'sc Quit sc
	}
	
	Set sc = ##class(%EnsembleMgr).EnableNamespace(Namespace, 0)
	If 'sc Quit ..BuildStatus("Error enabling Ensemble:", sc)
	
	Quit $$$OK
}

ClassMethod DisableEnsemble(Namespace As %String) As %Status
{
	Set sc = ##class(%EnsembleMgr).DisableNamespace(Namespace, 0)
	If 'sc Quit ..BuildStatus("Error disabling Ensemble:", sc)
	
	; Ensemble created a CSP application; delete it
	Set App = $System.CSP.GetDefaultApp(Namespace)
	If App '= "" {
		Set sc = ..DeleteCSPApplication(App)
		If 'sc Quit sc
	}
	
	Quit $$$OK
}

// -----

/// Helper to delete a resource
ClassMethod DeleteResource(Name As %String) As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	Set sc = ##class(Security.Resources).Delete(Name)
	If 'sc Quit ..BuildStatus("Error deleting resource {}:", sc, Name)
	
	Quit $$$OK
}

// -----

/// Deletes a CSP application.
ClassMethod DeleteCSPApplication(App As %String) As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	If '##class(Security.Applications).Exists(App) Quit $$$OK
	Set sc = ##class(Security.Applications).Get(App, .Properties)
	If 'sc Quit ..BuildStatus("Error determining properties for {}:", sc, App)
	Set Directory = $Get(Properties("Path"))
	
	Set sc = ##class(Security.Applications).Delete(App)
	If 'sc Quit ..BuildStatus("Error deleting {}:", sc, App)
	
	; Try to delete directory but ignore possible error.
	Set ok = ##class(%File).RemoveDirectory(Directory, .rc)
	
	Quit $$$OK
}

/// Adds a global mapping in Namespace to the specified database.
ClassMethod MapGlobal(Namespace As %String, Global As %String, Database As %String = "CACHETEMP") As %Status
{
	New $Namespace
	Do $ZUtil(5, "%SYS")
	
	If ##class(Config.MapGlobals).Exists(Namespace, Global) Quit $$$OK
	
	Set Properties("Database") = Database
	Set sc = ##class(Config.MapGlobals).Create(Namespace, Global, .Properties)
	If 'sc Quit ..BuildStatus("Error creating mapping in {} for global {} to database {}:", sc, Namespace, Global, Database)
	
	Quit $$$OK
}

/// Helper for creating updated status
ClassMethod BuildStatus(Message As %String, Status As %Status = "", Args... As %String) As %Status
{
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), 1, 1)
	}
	
	;Convert message to %Status
	Set MsgStatus = $System.Status.Error($$$GeneralError, Message)
	
	;Append status from parameter, if specified
	If Status '= "" Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	
	Quit MsgStatus
}

}

