/// Handles sources by synchronizing with a file system directory.
/// Checkin/out etc. is expected to be handled by an external program.
Class Strix.SCM.Handler.File Extends Strix.SCM.Handler.Base
{

/// Whether to synchronize the file on each save. This ensures the file is
/// always kept up to date with the Caché-version.
Property SyncToDisk As %Boolean [ InitialExpression = 0 ];

/// An instance of the class that handles the file IO.
/// Made transient so it won't be seen as a setting.
Property FileIO As Strix.SCM.FileIO [ Transient ];

// ===== Studio menu actions

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	;Assume we won't handle this action
	Set Action = 0, Target = "", Msg = "", Reload = 0
	
	;Studio-generated action (as opposed to menu item)
	If Type = 1 Quit $$$OK
	
	
	;===== Get project
	
	If InternalName = "" Quit $$$OK
	
	#dim Project As Strix.SCM.Project
	If '##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage, .Msg) {
		If Msg '= "" Set Action = 6 ; MessageBox
		Quit $$$OK
	}
	
	
	;== Export item
	
	If Name = "Source control,ExportItem", AsItem {
		Set Status = ..FileIO.ExportItem(.Filename, .Action, .Target)
		If 'Status Quit Status
		If Action {
			Write !,"== Launched "_Target
		} Else {
			Write !,"== "_InternalName_" exported to "_Filename_"."
		}
		Quit $$$OK
	}
	
	
	;== Export class data
	
	If Name = "Source control,ExportData", AsStorage {
		Set Status = ..FileIO.ExportClassData(.Filename)
		If 'Status Quit Status
		Write !,"== "_InternalName_" data exported to "_Filename_"."
		Quit $$$OK
	}
	
	
	;== Edit project
	
	If Name = "Source control,EditProject" {
		Set Action = 3
		Try { Set Host = $SYSTEM.TCPDevice.LocalAddr() } Catch (e) { Set Host = ##class(%Function).HostName() }
		Set Port = $Get(^%SYS("WebServer","Port"), "57772")
		Set App = $System.CSP.GetDefaultApp($ZUtil(5))
		Set Target = "http://"_Host_":"_Port_App_"/Strix.SCM.UI.cls"
		Set Target = Target_"?Page=Project&Project="_Project.GUID
		Quit $$$OK
	}
	
	
	;== Export project
	
	If Name = "Source control,ExportProject" {
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to export the entire project '"_Project.Name_"' to the working copy?"
		Quit $$$OK
	}
	
	
	;== Import project
	
	If Name = "Source control,ImportProject" {
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to import the entire project '"_Project.Name_"' from the working copy?"
		Quit $$$OK
	}
	
	
	;== Reload item
	
	If Name = "Source control,LoadItem", AsItem {
		Set Filename = Project.GetExportFilename(InternalName, , , .Status)
		If 'Status Quit Status
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to reload '"_InternalName_"' from file '"_Filename_"'?"
		Quit $$$OK
	}
	
	
	;== Reload data
	
	If Name = "Source control,LoadData", AsStorage {
		Set StorageName = InternalName, $$$ItemType(StorageName) = "stg"
		Set Filename = Project.GetExportFilename(StorageName, , , .Status)
		If 'Status Quit Status
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to reload data for '"_InternalName_"' from file '"_Filename_"'?"
		Quit $$$OK
	}
	
	
	;== Open folder
	
	If Name = "Source control,OpenFolder" {
		Set FullPath = Project.GetExportFilename(InternalName, .Directory, .Filename)
		Set Action = 3 ; Run exe
		Set Target = ..GetExplorerCommand(Directory, Filename)
		Quit $$$OK
	}
	
	
	;===== Fallback to Base handler
	
	Quit ##super(Type, Name, InternalName, SelectedText, .Action, .Target, .Msg, .Reload)
}

/// Implements actions that should only be done after user confirmation and/or input.
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Set Reload = 0
	
	
	;Studio-generated action (as opposed to menu item)
	If Type = 1 Quit $$$OK
	
	;User says no
	If Answer = 0 Quit $$$OK  ; No
	If Answer = 2 Quit $$$OK  ; Cancel
	
	
	;===== Get project
	
	#dim Project As Strix.SCM.Project
	If InternalName = "" Quit $$$OK
	If '##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage, .Msg) Quit $$$OK
	
	
	;== Export project
	
	If Name = "Source control,ExportProject" {
		Set Status = ..FileIO.ExportProject()
		If 'Status Quit Status
		Write "== Export of project finished successfully.",!
		Quit $$$OK
	}
	
	
	;== Import project
	
	If Name = "Source control,ImportProject" {
		Set Status = ..FileIO.ImportProject()
		If 'Status Quit Status
		Write "== Import of project finished successfully.",!
		Quit $$$OK
	}
	
	
	;== Reload item
	
	If Name = "Source control,LoadItem" {
		Set Status = ..FileIO.LoadItem(.Filename)
		If 'Status Quit Status
		Write !,"== Loaded "_InternalName_" from "_Filename_"."
		Quit $$$OK
	}
	
	;== Reload data
	
	If Name = "Source control,LoadData" {
		Set Status = ..FileIO.LoadClassData(.Filename)
		If 'Status Quit Status
		Write !,"== Loaded data for "_InternalName_" from "_Filename_"."
		Quit $$$OK
	}
	
	Quit $$$OK
}

/// Called when a menu item is to be displayed; determines what to display,
/// and whether the item should be enabled or not.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	;Top level menus always enabled
	If MenuName '[ "," Set Enabled = 1 Quit $$$OK
	
	;Get display name:
	Set ItemName = $Piece(MenuName, ",", 2)
	Set DisplayName = $Case(ItemName,
	  "ExportItem":          "Save item to disk",
	  "ExportData":          "Save data for item to disk",
	  "LoadItem":            "Reload item from disk",
	  "LoadData":            "Reload data for item from disk",
	  "EditProject":         "Edit project settings",
	  "ExportProject":       "Save project to disk",
	  "ImportProject":       "Load project from disk",
	  "OpenFolder":          "Open working copy folder",
	  "LaunchUserInterface": "Open user interface",
	  : MenuName
	)
	
	;===== Menus that don't depend on a known item
	
	If ItemName = "LaunchUserInterface" {
		Set Enabled = 1
		Quit $$$OK
	}
	
	;===== Menus that depend on a known item
	
	#dim Project As Strix.SCM.Project
	If ##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage) {
		;Default: enabled if known as item, otherwise not
		Set Enabled = $Select(AsItem: 1, 1: 0)
		
		;Exceptions:
		If ItemName = "ReloadItem" {
			If AsItem {
				Set Filename = Project.GetExportFilename(InternalName, , , .Status)
				Set Enabled = ##class(%File).Exists(Filename)
			} Else {
				Set Enabled = 0
			}
			
		} ElseIf (ItemName = "ExportData") || (ItemName = "LoadData") {
			Set Enabled = $Select(AsStorage: 1, 1: -1)
			
		}
		
	} Else {
		;Item unknown in project: don't display at all
		Set Enabled = -1
		
	}
	
	Quit $$$OK
}

// ===== Studio callbacks

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	If '..SyncToDisk Quit $$$OK
	If InternalName = "" Quit $$$OK
	
	#dim Project As Strix.SCM.Project
	If '##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage, .Msg) {
		Write Msg,!
		Quit $$$OK
	}
	
	Set Status = ..FileIO.ExportItem(.Filename)
	If 'Status Quit Status
	
	Write !,"== "_InternalName_" exported to "_Filename_"."
	
	Quit $$$OK
}

/// Compilation may have changed storage.
Method OnAfterCompile(InternalName As %String) As %Status
{
	If '..SyncToDisk Quit $$$OK
	If InternalName = "" Quit $$$OK
	
	; Normal processing first
	Set sc = ..OnAfterSave(InternalName)
	If 'sc Quit sc
	
	; Do the rest below only for BPLs
	
	Set Type = $$$NormalizedType(InternalName), ItemName = $$$ItemName(InternalName)
	If Type '= "bpl" {
		If Type '= "cls" Quit $$$OK
		If $$$comClassKeyGet(ItemName,$$$cCLASSprimarysuper) '[ "~Ens.BusinessProcessBPL~" Quit $$$OK
	}
	
	; Check if the Context class belonging to the BP is specified
	Set ItemName = ItemName_".Context.cls"
	If '##class(%Dictionary.ClassDefinition).%ExistsId(ItemName) Quit $$$OK
	If '..FileIO.Project.OwnsItem(ItemName, .AsItem) Quit $$$OK
	If 'AsItem Quit $$$OK
	
	; We are expected to export the context class as well; do so:
	Set ..FileIO.Item = ItemName
	Set sc = ..FileIO.ExportItem(.Filename)
	Set ..FileIO.Item = InternalName
	If 'sc Quit sc
	Write !,"== "_..FileIO.Item_" exported to "_Filename_"."
	
	Quit $$$OK
}

/// Delete on-disk version as well.
Method OnAfterDelete(InternalName As %String) As %Status
{
	If '..SyncToDisk Quit $$$OK
	If InternalName = "" Quit $$$OK
	
	; Get project this item belongs to
	#dim Project As Strix.SCM.Project
	If '##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage, .Msg) {
		Write Msg,!
		Quit $$$OK
	}
	
	; Determine filename
	Set Filename = Project.GetExportFilename(InternalName, , , .Status)
	If 'Status Quit Status
	
	; If it doesn't exists we're done
	If '##class(%File).Exists(Filename) Quit $$$OK
	
	; Delete
	Set ok = ##class(%File).Delete(Filename, .rc)
	If 'ok Write !,$$$BuildStr("== Error {} deleting {}.", rc, Filename) Quit $$$OK
	
	Write !,"== Deleted "_Filename_"."
	
	Quit $$$OK
}

// ===== Menus and menu items

/// Returns a list of menu items for the top-level menu. In addition to
/// the menu name, the name of the current document and the currently
/// selected text are passed in.
Method GetMenuItems(MenuName As %String, InternalName As %String, SelectedText As %String, Output Status As %Status) As %List
{
	Set Status = $$$OK
	
	;Items is a list of lists containing:
	;  Name, Enabled, Save before execute, is separator
	
	Set Items = ##super(MenuName, InternalName, SelectedText, .Status)
	If 'Status Quit Items
	
	Set Items = Items_$lb(
	  ;Name, Enabled, Save before execute, is separator
  	$lb("", 1, 0, 1),
	  $lb("EditProject", 1, 0, 0),
  	$lb("OpenFolder", 1, 0, 0),
	  $lb("ExportProject", 1, 1, 0),
	  $lb("ImportProject", 1, 0, 0),
  	$lb("", 1, 0, 1),
	  $lb("ExportItem", 1, 1, 0),
	  $lb("ExportData", 0, 0, 0),
	  $lb("LoadItem", 1, 1, 0),
	  $lb("LoadData", 0, 0, 0)
	)
	
	Quit Items
}

// ===== Helpers

/// Returns a command to open explorer in the given directory. Optionally,
/// a file to pre-select can be specified.
ClassMethod GetExplorerCommand(Directory As %String, File As %String = "") As %String
{
	If File '= "" {
		Set Path = ##class(%File).SubDirectoryName(Directory, File)
		If '##class(%File).Exists(Path) Set File = ""
	}
	
	If File = "" {
		Set Cmd = "C:\Windows\explorer.exe /e /root,"_Directory
	} Else {
		Set Cmd = "C:\Windows\explorer.exe /e,/select,"_Path
	}
	
	Quit Cmd
}

}

