Include Strix

Class Strix.SCM.Handler.Git Extends Strix.SCM.Handler.File
{

/// Full path and filename of the git executable.
Property GitPath As %String;

/// Full path and filename of the TortoiceGitProc.exe executable.
Property GitGuiPath As %String;

/// Full path to release base directory; releases are created below it.
Property ReleasePath As %String;

/// The name to use for the release directory. Default is R{rev}.\
/// Available variables:
/// {rev}: revision number
/// {date}: date (format YYYY-MM-DD)
Property ReleaseName As %String;

/// Comma-separated list of release post-processors to run. Available \
/// processors are:
/// • EnsProdDir: Moves Ensemble Production classes to a subdirectory "Productions".
/// • RemoveCfgFile: Removes the SCM configuration file from the release.
/// • RemoveEnsProd: Removes Ensemble Production classes from the export.
/// • Zip: Zips the release directory.
Property PostProcessors As %String(MAXLEN = 80);

// =====

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
		If Msg '= "" Set Action = 6 ; MesssageBox
		Quit $$$OK
	}
	
	
	;== Delete item
	
	If Name = "Source control,Delete", AsItem {
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to delete '"_InternalName_"'?"
		Quit $$$OK
	}
	
	
	;== Checkin
	
	If Name = "Source control,Checkin" {
		Set Target = ..GetGUICommand("/command:commit /path:"_Project.GetProjectPath(), .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Set Action = 3 ; Run executable
		Quit $$$OK
	}
	
	
	;== Show log
	
	If Name = "Source control,ShowLog" {
		Set Target = ..GetGUICommand("/command:log /path:"_Project.GetProjectPath(), .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Set Action = 3 ; Run executable
		Quit $$$OK
	}
	
	
	;== Show item log
	
	If Name = "Source control,ShowItemLog", AsItem {
		Set Filename = Project.GetExportFilename(InternalName, , , .Status)
		If 'Status Quit Status
		Set Target = ..GetGUICommand("/command:log /path:"""_Filename_"""", .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Set Action = 3 ; Run executable
		Quit $$$OK
	}
	
	
	;== Show diff
	
	If Name = "Source control,ShowDiff", AsItem {
		Set Filename = Project.GetExportFilename(InternalName, , , .Status)
		If 'Status Quit Status
		Set Target = ..GetGUICommand("/command:diff /path:"""_Filename_"""", .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Set Action = 3 ; Run executable
		Quit $$$OK
	}
	
	
	;== Create tag
	
	If Name = "Source control,CreateTag" {
		Set Target = ..GetGUICommand("/command:tag /path:"""_Project.GetProjectPath()_"""", .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Set Action = 3 ; Run executable
		Quit $$$OK
	}
	
	
	;===== Fallback to File handler
	
	Quit ##super(Type, Name, InternalName, SelectedText, .Action, .Target, .Msg, .Reload)
}

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
	If '##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage, .ErrorMsg) {
		Write !,ErrorMsg,!
		Quit $$$OK
	}
	
	
	;===== Delete item
	
	If Name = "Source control,Delete", AsItem {
		Set Filename = Project.GetExportFilename(InternalName, , , .Status)
		If 'Status Quit Status
		
		If ##class(%File).Exists(Filename) {
			;Delete from source control
			Set Output = ..GetCommandOutput(Project.GetProjectPath(), "rm --force --quiet """_Filename_"""", , .ErrorMsg)
			If ErrorMsg '= "" Write !,"=== Error deleting "_Filename_":",!,ErrorMsg,! Quit $$$OK
			Write !,"=== Deleted "_Filename_"."
		}
		
		Set Status = $System.OBJ.Delete(InternalName, "d")
		If 'Status Quit Status
		
		Quit $$$OK
	}
	
	
	;===== Fallback to File handler
	
	Quit ##super(Type, Name, InternalName, Answer, .Msg, .Reload)
}

/// Called when a menu item is to be displayed; determines what to display,
/// and whether the item should be enabled or not.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Set ItemName = $Piece(MenuName, ",", 2)
	Set Name = $Case(ItemName,
	  ;"ShowRevisions": "Revisions for "_InternalName_"",
	  "Delete": "Delete item",
	  "Checkin": "Open checkin dialog",
	  "ShowLog": "View repository log",
	  "ShowItemLog": "View log ",
	  "ShowDiff": "View diff",
	  ;"MakeRelease": "Make release",
	  "CreateTag": "Create tag",
	  : ""
	)
	
	;If we didn't handle this item, fall back to super
	If Name = "" Quit ##super(MenuName, InternalName, SelectedText, .Enabled, .DisplayName)
	
	Set DisplayName = Name
	
	#dim Project As Strix.SCM.Project
	If ##class(Strix.SCM.Project).CheckItem(.InternalName, .Project, .AsItem, .AsStorage) {
		;Enabled if known as item, otherwise not
		Set Enabled = $Select(AsItem: 1, 1: 0)
		
	}
	
	Quit $$$OK
}

// =====

/// Appends this handlers menus to those of the superclass.
ClassMethod GetMenuItems(MenuName As %String, InternalName As %String, SelectedText As %String, Output Status As %Status) As %List
{
	;Get items for file handler
	Set Items = ##super(MenuName, InternalName, SelectedText, .Status)
	If 'Status Quit Items
	
	;Items is a list of lists containing:
	;  Name, Enabled, Save before execute, is separator
	
	;Append subversion-specific items
	Set Items = Items_$lb(
	  $lb("", 1, 0, 1),
	  $lb("ShowDiff", 1, 0, 0),
	  $lb("ShowItemLog", 1, 1, 0),
	  $lb("Delete", 1, 1, 0),
	  $lb("", 1, 0, 1),
	  $lb("ShowLog", 1, 0, 0),
	  $lb("Checkin", 1, 1, 0),
	  ;$lb("MakeRelease", 1, 1, 0),
	  $lb("CreateTag", 1, 1, 0),
	)
	
	Quit Items
}

// =====

/// Helper for MakeRelease: runs post-processors
Method HandlePostProcessors(Project As Strix.SCM.Project, Revision As %String, ReleasePath As %String, Output ErrorMsg As %String) As %Status
{
	Set ErrorMsg = ""
	
	For i = 1:1:$Length(..PostProcessors, ",") {
		Set ClassName = $ZStrip($Piece(..PostProcessors, ",", i), "<>W")
		
		;If no package specified, default to the Strix processors package
		If ClassName '[ ".", ##class(%Dictionary.ClassDefinition).%ExistsId("Strix.SCM.Processor."_ClassName) {
			Set ClassName = "Strix.SCM.Processor."_ClassName
		}
		; Skip non-release handlers
		Set Type = $Parameter(ClassName, "HandlerType")
		If Type '= "Release" Continue
		
		Write "== Running postprocessor "_ClassName,!
		
		#dim Processor As Strix.SCM.Processor.Base
		Set Processor = ##class(Strix.SCM.Processor.Base).Get(ClassName, $this, Project, .Status)
		If 'Status {
			Set ErrorMsg = "Error getting postprocessor "_ClassName_": "_$System.Status.GetErrorText(Status)
			Return $$$OK
		}
		Set Status = Processor.Run(Revision, ReleasePath)
		If 'Status {
			Set ErrorMsg = "Error running postprocessor "_ClassName_": "_$System.Status.GetErrorText(Status)
			Return $$$OK
		}
		
		Write "== Successfully ran postprocessor.",!
	}
	
	Quit $$$OK
}

// =====

/// Returns the output of an svn command (to be passed in without
/// specifying the executable path). If Split is true, returns it
/// as a list of lines, already stripped. If an error occurs, the
/// output parameter ErrorMsg will contain information. A timeout
/// may occur on the Read if Cache does not have permission to
/// read the repository.
Method GetCommandOutput(ProjectPath As %String = "", Command As %String, Split As %Boolean = 0, Output ErrorMsg As %String) As %ListOfObjects
{
	; Prefix command with normalized path to svn executable
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(..GitPath)
	Set Command = Executable_" "_Command
	
	; Git commands need the current directory to be in the working directory.
	Set CurrentDir = ##class(%SYSTEM.Process).CurrentDirectory(ProjectPath)
	
	;Get output
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , .ErrorMsg)
	
	; Restore current directory to what it was
	Do ##class(%SYSTEM.Process).CurrentDirectory(CurrentDir)
	
	If ErrorMsg '= "" Quit ""
	If Result ? 1(1"error",1"fatal")1":".E Set ErrorMsg = Result Quit ""
	
	If Split Set Result = ##class(Strix.Lib.String).SplitLines(Result)
	
	Quit Result
}

Method GetGUICommand(Command As %String, Output ErrorMsg As %String) As %String
{
	Set ErrorMsg = ""
	
	If '##class(%File).Exists(..GitGuiPath) {
		Set ErrorMsg = "Option not available: TortoiseGit executable '"_..GitGuiPath_"' not found."
		Quit ""
	}
	
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(..GitGuiPath)
	Set Command = Executable_" "_Command
	
	Quit Command
}

}

