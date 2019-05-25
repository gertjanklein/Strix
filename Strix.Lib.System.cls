<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.System">
<Description>
Various utility methods</Description>
<IncludeCode>Strix</IncludeCode>
<Super>%RegisteredObject</Super>
<TimeCreated>64380,39933.025974</TimeCreated>

<Method name="GetDatabaseDirectory">
<Description>
Returns the directory for the database with the given name.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>DatabaseName:%String,*Status:%Status,*Properties:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	New $Namespace
	
	;The system class we use is only accessible from %SYS
	Set $Namespace = "%SYS"
	
	Set Status = ##class(Config.Databases).Get(DatabaseName, .Properties)
	If 'Status Quit ""
	
	Set Result = Properties("Directory")
	
	Quit Result
]]></Implementation>
</Method>

<Method name="CacheLibReadOnly">
<Description>
Gets/sets the readonly flag for the CACHELIB database. If the
parameter ReadOnly is not specified, no changes will be made.
If specified, the requested setting will be applied and the
previous value will be returned.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>ReadOnly:%Boolean="",*Status:%Status</FormalSpec>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
	New $Namespace, %objlasterror
	
	Set Directory = ..GetDatabaseDirectory("CACHELIB", .Status)
	If 'Status Set Status = $$$BuildErr("Error determining CACHELIB database directory:", Status) Quit ""
	
	;The system class we use is only accessible from %SYS
	Set $Namespace = "%SYS"
	
	Set Database = ##class(SYS.Database).%OpenId(Directory, , .Status)
	If 'Status {
		Set Status = $$$BuildErr("Error opening CACHELIB database object:", Status)
		Quit ""
	}
	
	Set PrevState = Database.ReadOnly
	
	If ReadOnly '= "", ReadOnly '= PrevState {
		Set Database.ReadOnly = ReadOnly
		Set Status = Database.%Save()
		If 'Status {
			Kill Database
			Set Status = $$$BuildErr("Error changing CACHELIB ReadOnly setting to {}:", Status, ReadOnly)
			Quit ""
		}
	}
	
	Kill Database
	
	Return PrevState
]]></Implementation>
</Method>

<Method name="MemoryUsed">
<Description>
Returns the amount of memory used (in bytes) in the current process.
$ZStorage returns the maximum available memory (in kB)
$Storage returns the currently available memor (in bytes)</Description>
<ClassMethod>1</ClassMethod>
<CodeMode>expression</CodeMode>
<ReturnType>%Integer</ReturnType>
<Implementation><![CDATA[($ZStorage*1024) - $Storage
]]></Implementation>
</Method>
</Class>
</Export>
