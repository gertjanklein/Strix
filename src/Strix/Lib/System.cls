Include Strix

/// Various utility methods
Class Strix.Lib.System Extends %RegisteredObject
{

/// Returns the directory for the database with the given name.
ClassMethod GetDatabaseDirectory(DatabaseName As %String, Output Status As %Status, Output Properties As %String) As %String
{
	New $Namespace
	
	;The system class we use is only accessible from %SYS
	Set $Namespace = "%SYS"
	
	Set Status = ##class(Config.Databases).Get(DatabaseName, .Properties)
	If 'Status Quit ""
	
	Set Result = Properties("Directory")
	
	Quit Result
}

/// Gets/sets the readonly flag for the CACHELIB database. If the
/// parameter ReadOnly is not specified, no changes will be made.
/// If specified, the requested setting will be applied and the
/// previous value will be returned.
ClassMethod CacheLibReadOnly(ReadOnly As %Boolean = "", Output Status As %Status) As %Boolean
{
	New $Namespace, %objlasterror
	
	Set Name = $Select($ZV["IRIS": "IRISLIB", 1:"CACHELIB")
	Set Directory = ..GetDatabaseDirectory(Name, .Status)
	If 'Status Set Status = $$$BuildErr("Error determining {} database directory:", Status, Name) Quit ""
	
	;The system class we use is only accessible from %SYS
	Set $Namespace = "%SYS"
	
	Set Database = ##class(SYS.Database).%OpenId(Directory, , .Status)
	If 'Status {
		Set Status = $$$BuildErr("Error opening {} database object:", Status, Name)
		Quit ""
	}
	
	Set PrevState = Database.ReadOnly
	
	If ReadOnly '= "", ReadOnly '= PrevState {
		Set Database.ReadOnly = ReadOnly
		Set Status = Database.%Save()
		If 'Status {
			Kill Database
			Set Status = $$$BuildErr("Error changing {} ReadOnly setting to {}:", Status, Name, ReadOnly)
			Quit ""
		}
	}
	
	Kill Database
	
	Return PrevState
}

/// Returns the amount of memory used (in bytes) in the current process.
/// $ZStorage returns the maximum available memory (in kB)
/// $Storage returns the currently available memor (in bytes)
ClassMethod MemoryUsed() As %Integer [ CodeMode = expression ]
{
($ZStorage*1024) - $Storage
}

}

