Include Strix

Class Strix.SCM.Handler.Subversion Extends Strix.SCM.Handler.File
{

/// Full path and filename of the SVN executable.
Property SvnPath As %String;

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
	
	
	;== Show revisions
	
	If Name = "Source control,ShowRevisions", AsItem {
		Set Filename = Project.GetExportFilename(InternalName, , , .Status)
		If 'Status Quit Status
		
		Set Output = ..GetCommandOutput("log """_Filename_"""", 1, .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		
		Write !,"== Revision history for "_InternalName_":"
		For i = 1:1:Output.Count() {
			Set Line = Output.GetAt(i)
			
			If Line ?1."-" Continue
			If Line = "" Continue
			
			If Line ? 1"r"1.N1.E {
				;Keep empty line between revisions
				Write !
			} Else {
				;Indent comment line(s)
				Write "  "
			}
			
			Write Line,!
		}
		
		Quit $$$OK
	}
	
	
	;== Delete item
	
	If Name = "Source control,Delete", AsItem {
		Set Action = 1 ;Yes/no/cancel
		Set Target = "Are you sure you want to delete '"_InternalName_"'?"
		Quit $$$OK
	}
	
	
	;== Status
	
	If Name = "Source control,Status" {
		Write !,"== Working copy status:"
		Set Output = ..GetCommandOutput("status -u """_Project.GetProjectPath()_"""", , .ErrorMsg)
		If ErrorMsg '= "" Write ErrorMsg,! Quit $$$OK
		Write !,Output,!
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
	
	
	;== Make release
	
	If Name = "Source control,MakeRelease" {
		If ..ReleasePath '= "" {
			Set Target = "Please specify the revision to create a release for:"
			Set Msg = "HEAD"
			Set Action = 7 ; Ask user for input
		} Else {
			Set Action = 6 ;Alert
			Set Target = "No release path configured."
		}
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
			Set Output = ..GetCommandOutput("delete --force """_Filename_"""", , .ErrorMsg)
			If ErrorMsg '= "" Write !,ErrorMsg,! Quit $$$OK
			If Output [ "svn: E" Write !,Output,! Quit $$$OK
		}
		
		Set Status = $System.OBJ.Delete(InternalName, "d")
		If 'Status Quit Status
		
		Quit $$$OK
	}
	
	
	;== Make release
	
	If Name = "Source control,MakeRelease" {
		Set Status = ..MakeRelease(Project, Msg, .ErrorMsg)
		If ErrorMsg '= "" Write !,ErrorMsg,!
		Quit Status
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
	  "ShowRevisions": "Revisions for "_InternalName_"",
	  "Delete": "Delete",
	  "Status": "Working copy status",
	  "Checkin": "Open checkin dialog",
	  "ShowLog": "View repository log",
	  "ShowItemLog": "View log ",
	  "ShowDiff": "View diff",
	  "MakeRelease": "Make release",
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
	  ;$lb("Status", 1, 1, 0),
	  $lb("ShowLog", 1, 0, 0),
	  $lb("Checkin", 1, 1, 0),
	  $lb("MakeRelease", 1, 1, 0),
	)
	
	Quit Items
}

// =====

/// Implements the MakeRelease menu item
Method MakeRelease(Project As Strix.SCM.Project, Revision As %String, Output ErrorMsg As %String) As %Status
{
	Set ErrorMsg = ""
	
	;Get project directory
	Set Dir = Project.GetProjectPath(.Status)
	If 'Status Quit $$$BuildErr("Error determining project path", Status)
	
	;Get corresponding repository URL
	Set Url = ..GetCommandOutput("info --show-item url """_Dir_"""", , .ErrorMsg)
	If ErrorMsg '= "" Quit $$$OK
	If Url ? 1"svn: E"1.E Set ErrorMsg = "Error determining repository Url: "_Url Quit $$$OK
	
	If Revision = "HEAD" {
		Set Revision = ..GetCurrentRevision(Dir, .ErrorMsg)
		If ErrorMsg '= "" Quit $$$OK
	}
	
	;Determine release directory name:
	Set Name = ..ReleaseName
	If Name = "" Set Name = "R{rev}"
	;Convert name to position 
	Set Name = $Replace(Name, "{rev}", "{1}",,,1)
	Set Name = $Replace(Name, "{date}", "{2}",,,1)
	Set Name = $$$BuildStr(Name, Revision, $ZDate($Horolog, 3))
	
	;Determine directory for release
	Set ReleasePath = ##class(%File).SubDirectoryName(..ReleasePath, Name)
	
	;Export from SCM
	Write !,"== Exporting revision "_Revision_" to "_ReleasePath,!
	Set Output = ..GetCommandOutput("export -r "_Revision_" --force "_Url_" """_ReleasePath_"""", , .ErrorMsg)
	If ErrorMsg '= "" Quit $$$OK
	
	If Output ? 1"svn: E"1.E Set ErrorMsg = "Error exporting revision: "_Output Quit $$$OK
	
	Write "== Release "_Revision_" exported successfully.",!
	
	If ..PostProcessors '= "" {
		Set Status = ..HandlePostProcessors(Project, Revision, ReleasePath, .ErrorMsg)
		If 'Status Quit Status
		If ErrorMsg '= "" Quit $$$OK
	}
	
	Quit $$$OK
}

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
Method GetCommandOutput(Command As %String, Split As %Boolean = 0, Output ErrorMsg As %String) As %ListOfObjects
{
	; Prefix command with normalized path to svn executable
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(..SvnPath)
	Set Command = Executable_" "_Command
	
	;Get output
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , , .ErrorMsg)
	If ErrorMsg '= "" Quit ""
	
	If Split Set Result = ##class(Strix.Lib.String).SplitLines(Result)
	
	Quit Result
}

Method GetCurrentRevision(ItemPath As %String, Output ErrorMsg As %String) As %String
{
	;Split executable in file and directory
	Set Dir = ##class(%File).GetDirectory(..SvnPath)
	Set File = ##class(%File).GetFilename(..SvnPath)
	
	;Change executable; we need svnversion
	Set File = $Replace(File, "svn", "svnversion")
	Set Executable = ##class(%File).SubDirectoryName(Dir, File)
	
	;Normalize spaces
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(Executable)
	
	;Build full command
	Set Command = Executable_" """_ItemPath_""""
	
	;Get output
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , , .ErrorMsg)
	If ErrorMsg '= "" Quit ""
	
	If $Extract(Result) '? 1N Set ErrorMsg = "Error determining current revision: "_Result Quit ""
	
	;If multiple revisions for this item, we want the latest
	If Result [ ":" Set Result = $Piece(Result, ":", 2)
	
	;Strip modifier flags
	Set Result = +Result
	
	Quit Result
}

Method GetGUICommand(Command As %String, Output ErrorMsg As %String) As %String
{
	Set ErrorMsg = ""
	
	Set Dir = ##class(%File).GetDirectory(..SvnPath)
	Set Executable = ##class(%File).SubDirectoryName(Dir, "TortoiseProc.exe")
	
	If '##class(%File).Exists(Executable) {
		Set ErrorMsg = "Option not available: TortoiseSVN executable '"_Executable_"' not found."
		Quit ""
	}
	
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(Executable)
	Set Command = Executable_" "_Command
	
	Quit Command
}

}

