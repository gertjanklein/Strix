Include Strix.SCM

/// Base handler for Studio callbacks, with do-nothing implementations.
/// Proper handlers subclass this one and implement what they need.
Class Strix.SCM.Handler.Base Extends %RegisteredObject [ DependsOn = Strix.Generator.Utilities ]
{

/// This parameter specifies, by property name, which settings for this
/// handler need to be included in the project configuration file. All
/// other settings are considered local to the project. Property names
/// must be separated by commas.
Parameter GlobalSettings As STRING;

/// Studio login credentials
Property Credentials As %List [ Transient ];

// =====

/// Returns a %List of settings applicable to this class. Each setting
/// is returned as a %List with: name, type, origin
ClassMethod GetSettings() As %List [ CodeMode = objectgenerator ]
{
	Set Result = ""
	
	;Get list of settings to save in config file
	Set GlobalSettings = $ListFromString(##class(Strix.Generator.Utilities).GetParameterValue(%compiledclass, "GlobalSettings"))
	
	Set Key = ""
	For  {
		#dim Prop As %Dictionary.CompiledProperty
		Set Prop = %compiledclass.Properties.GetNext(.Key)
		If Key = "" Quit
		
		; Skip private and system properties
		If Prop.Private Continue
		If $Extract(Prop.Name) = "%" Continue
		
		; The Transient flag indicates this property should not be
		; considered a setting.
		If Prop.Transient Continue
		
		If Result '= "" Set Result = Result_","
		
		Set Name = Prop.Name
		Set Type = $$$DenormalizeClassname(Prop.Type)
		Set Origin = Prop.Origin
		
		;Is this a global project setting?
		Set IsGlobal = ''$ListFind(GlobalSettings, Name)
		
		Set Result = Result_"$lb("""_Name_""","""_Type_""","""_Origin_""","_IsGlobal_")"
	}
	
	If Result '= "" {
		Set Result = "Quit $lb("_Result_")"
	} Else {
		Set Result = "Quit """""
	}
	
	Do %code.WriteLine($Char(9)_Result)
	
	Quit $$$OK
}

/// Returns the (property) description for a specific setting,
ClassMethod GetSettingDescription(ClassName As %String, Setting As %String, AsHTML As %Boolean = 1, Output Status As %Status) As %String
{
	Set Def = ##class(%Dictionary.PropertyDefinition).%OpenId(ClassName_"||"_Setting, , .Status)
	If 'Status Set Status = $$$BuildErr("Error opening definion for "_ClassName_":"_Setting_":", Status) Quit ""
	Set Desc = $ZStrip(Def.Description, "<>W")
	If AsHTML {
		Set Desc = $ZConvert(Desc, "O", "HTML")
		Set Desc = $Replace(Desc, "\"_$Char(13,10), " ")
		Set Desc = $Replace(Desc, $Char(13,10), "<br>"_$Char(13, 10))
	}
	Quit Desc
}

// ===== Studio menu actions

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	;All menus defined here are always enabled
	Set Enabled = 1
	
	;Top level menu
	If MenuName '[ "," Quit $$$OK
	
	;Get display name:
	Set SubMenuName = $Piece(MenuName, ",", 2)
	Set DisplayName = $Case(SubMenuName,
	  "LaunchUserInterface": "Open user interface",
	  : MenuName
	)
	
	Quit $$$OK
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	;Defaults
	Set Action = 0, Target = "", Msg = "", Reload = 0
	
	;Studio-generated action (as opposed to menu item)
	If Type = 1 Quit $$$OK
	
	If Name = "Source control,LaunchUserInterface" {
		Set Action = 3
		Try { Set Host = $SYSTEM.TCPDevice.LocalAddr() } Catch (e) { Set Host = ##class(%Function).HostName() }
		Set Port = $Get(^%SYS("WebServer","Port"), "57772")
		Set App = $System.CSP.GetDefaultApp($ZUtil(5))
		Set Target = "http://"_Host_":"_Port_App_"/Strix.SCM.UI.cls"
		Quit $$$OK
	}
	
	
	Set Action = 6 ; Messagebox
	Set Target = "Unimplemented menu: "_Name
	
	
	Quit $$$OK
}

Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Quit $$$OK
}

// ===== Studio callbacks

Method OnBeforeLoad(InternalName As %String) As %Status
{
	Quit $$$OK
}

Method OnAfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
	Quit $$$OK
}

Method OnBeforeCompile(InternalName As %String, ByRef qstruct As %String) As %Status
{
	Quit $$$OK
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	Quit $$$OK
}

Method OnBeforeDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

Method OnAfterDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

// ===== PostProcessor callbacks

/// Callback to handle messages from a postprocessor.
Method HandlePostProcessorOutput(Text As %String)
{
	Write "   "_Text,!
}

// ===== Menus and menu items

/// Returns a list with the top level menus appropriate for this
/// handler. These are shared between handlers (unless overridden).
/// Used by the Studio plugin.
ClassMethod GetMainMenus(Output Status As %Status) As %List
{
	Set Status = $$$OK
	;Call the menus "Source control", insert in both menu bar
	;and context menu.
	Set Menus = $lb($lb("Source control", 0), $lb("Source control", 1))
	Quit Menus
}

/// Returns the menu items for a given menu and document
ClassMethod GetMenuItems(MenuName As %String, InternalName As %String, SelectedText As %String, Output Status As %Status) As %List
{
	Set Status = $$$OK
	
	;Menus that are always valid, regardless of which item is selected
	Set Items = $lb(
	  $lb("LaunchUserInterface", 1, 0, 0)
	)
	
	Quit Items
}

}

