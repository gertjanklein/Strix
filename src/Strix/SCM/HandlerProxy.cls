Include Strix.SCM

/// Base handler: determines the appropriate handler to use.
Class Strix.SCM.HandlerProxy Extends %RegisteredObject
{

/// Credentials used to log in with Studio
Property Credentials As %List;

// ===== Studio menu handlers

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.UserAction(Type, Name, InternalName, SelectedText, .Action, .Target, .Msg, .Reload)
}

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnMenuItem(MenuName, InternalName, SelectedText, .Enabled, .DisplayName)
}

Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.AfterUserAction(Type, .Name, InternalName, Answer, Msg, .Reload)
}

// ===== Studio callbacks

Method OnBeforeLoad(InternalName As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnBeforeLoad(InternalName)
}

Method OnAfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnAfterLoad(InternalName, Object)
}

Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnBeforeSave(InternalName, Location, Object)
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnAfterSave(InternalName, Object)
}

Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnAfterStorage(InternalName, Location)
}

Method OnBeforeCompile(InternalName As %String, ByRef qstruct As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnBeforeCompile(InternalName, .qstruct)
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnAfterCompile(InternalName)
}

Method OnBeforeDelete(InternalName As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnBeforeDelete(InternalName)
}

Method OnAfterDelete(InternalName As %String) As %Status
{
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set Handler.Credentials = ..Credentials
	Quit Handler.OnAfterDelete(InternalName)
}

// ===== Other forwarded methods

Method GetMainMenus(Output Status As %Status) As %List
{
	Set Handler = ##class(Strix.SCM.Handler.Base).%New()
	Set Handler.Credentials = ..Credentials
	Quit Handler.GetMainMenus(.Status)
}

Method GetMenuItems(Output Status As %Status) As %List
{
	Set Handler = ##class(Strix.SCM.Handler.Base).%New()
	Set Handler.Credentials = ..Credentials
	Quit Handler.GetMenuItems(.Status)
}

// ===== Helpers

/// Returns a list of classnames of all available handlers.
ClassMethod GetHandlers(Output Handlers As %ListOfDataTypes) As %Status
{
	Set Handlers = ##class(%ListOfDataTypes).%New()
	
	Set stm = ##class(%SQL.Statement).%New()
	Set sc = stm.%PrepareClassQuery("%Dictionary.ClassDefinitionQuery","SubclassOf")
	If 'sc Quit $$$BuildErr("Error preparing SubclassOf query:", sc)
	#dim rs As %SQL.StatementResult
	Set rs = stm.%Execute("Strix.SCM.Handler.Base")
	
	While rs.%Next() {
		Set Name = rs.%Get("Name")
		Do Handlers.Insert(Name)
	}
	
	Quit $$$OK
}

// =====

Method %OnNew(Credentials As %List = "") As %Status [ Private, ServerOnly = 1 ]
{
	Set ..Credentials = Credentials
	Quit $$$OK
}

}
