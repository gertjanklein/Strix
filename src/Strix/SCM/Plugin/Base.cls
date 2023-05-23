Include Strix

Class Strix.SCM.Plugin.Base Extends %RegisteredObject
{

/// The current handler, if any
Property Handler As Strix.SCM.Handler.Base;

/// The internal name of the current item in Studio, if any
Property InternalName As %String;

/// The currently selected text in the current Studio document
Property SelectedText As %String;

// =====

/// Get a list of all menu items for all plugins that define them
ClassMethod GetPluginMenus(Handler As Strix.SCM.Handler.Base, InternalName As %String, SelectedText As %String, Output Status As %Status) As %List
{
	#dim Plugins As %ListOfDataTypes
	Set Status = ..GetPlugins(.Plugins)
	If 'Status Quit ""
	
	Set AllMenus = ""
	For i = 1:1:Plugins.Count() {
		Set Name = Plugins.GetAt(i)
		
		#dim Plugin As Strix.SCM.Plugin.Base
		Set Plugin = $ClassMethod(Name, "%New", Handler, InternalName, SelectedText)
		If 'Plugin {
			Set Status = $$$BuildStatus("Error instantiating plugin {}:", %objlasterror, Name)
			Return ""
		}
		
		Set PluginMenus = Plugin.GetMenus()
		If PluginMenus = "" Continue
		
		; Add a separator before the first plugin
		If AllMenus = "" Set AllMenus = $lb($lb("", 1, 0, 1))
		
		Set AllMenus = AllMenus_PluginMenus
	}
	
	Quit AllMenus
}

Method GetMenus() As %List [ Abstract ]
{
	Quit ""
}

// =====

ClassMethod GetDisplayName(Handler As Strix.SCM.Handler.Base, Index As %Integer, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Set Enabled = 0
	Set DisplayName = "[Unknown item]"
	Quit $$$OK
}

ClassMethod UserAction(Handler As Strix.SCM.Handler.Base, Index As %Integer, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	Quit $$$OK
}

ClassMethod AfterUserAction(Handler As Strix.SCM.Handler.Base, Index As %Integer, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Quit $$$OK
}

// =====

/// Returns a list of classnames of all available plugins.
ClassMethod GetPlugins(Output Plugins As %ListOfDataTypes) As %Status
{
	Set Plugins = ##class(%ListOfDataTypes).%New()
	
	Set stm = ##class(%SQL.Statement).%New()
	Set sc = stm.%PrepareClassQuery("%Dictionary.ClassDefinitionQuery","SubclassOf")
	If 'sc Quit $$$BuildErr("Error preparing SubclassOf query:", sc)
	#dim rs As %SQL.StatementResult
	Set rs = stm.%Execute("Strix.SCM.Plugin.Base")
	
	While rs.%Next() {
		Set Name = rs.%Get("Name")
		Do Plugins.Insert(Name)
	}
	
	Quit $$$OK
}

Method %OnNew(Handler As Strix.SCM.Handler.Base = "", InternalName As %String = "", SelectedText As %String = "") As %Status
{
	Set ..Handler = Handler
	Set ..InternalName = InternalName
	Set ..SelectedText = SelectedText
	Quit $$$OK
}

}
