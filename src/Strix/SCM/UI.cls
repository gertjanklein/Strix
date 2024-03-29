Include Strix

Class Strix.SCM.UI Extends Strix.SCM.UI.Support
{

ClassMethod OnPreHTTP() As %Boolean [ PublicList = (ErrorMsg, Message, Config, Project, Page) ]
{
	If %request.Get("img") '= "" Quit ##class(Strix.SCM.UI.Resources).OnPreHTTP()
	
	Set (ErrorMsg, Message) = ""
	Set Config = ##class(Strix.SCM.Config).Get()
	
	Set Page = %request.Get("Page")
	
	;More than one page needs a project object
	If Page = "Project" || (Page = "Import") {
		Set ProjectId = %request.Get("Project")
		If ProjectId '= "" {
			Set Project = ##class(Strix.SCM.Project).%OpenId(ProjectId, , .sc)
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error opening project object:", sc) Quit 1
		} Else {
			Set Project = ##class(Strix.SCM.Project).%New()
		}
	} Else {
		Set Project = ""
	}
	
	If Page = "Project" {
		If %request.IsDefined("Save") {
			Set sc = ..SaveProject(Config, Project)
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error saving project object:", sc) Quit 1
			;Redirect to self so refresh does no harm
			Set %response.Redirect = ..%ClassName(1)_".cls?Page=Project&Project="_..EscapeURL(Project.%Id())_"&msg=sok"
			
		} ElseIf %request.IsDefined("Export") {
			;Currently hardcoded for file handler
			Set sc = ##class(Strix.SCM.FileIO).ExportProject(Project, 1)
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error exporting project:", sc) Quit 1
			Set %response.Redirect = ..%ClassName(1)_".cls?Page=Project&Project="_..EscapeURL(Project.%Id())_"&msg=eok"
			
		} ElseIf %request.IsDefined("Copy") {
			Set New = ##class(Strix.SCM.Project).%New()
			Do New.CopyFrom(Project)
			Set New.Name = New.Name_" (copy)"
			Set New.GUID = $System.Util.CreateGUID()
			Set sc = New.%Save()
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error saving new project:", sc) Quit 1
			Set %response.Redirect = ..%ClassName(1)_".cls?Page=Project&Project="_..EscapeURL(New.%Id())
			
		} ElseIf %request.IsDefined("Delete") {
			Set sc = ..DeleteProject(Project)
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error deleting project object:", sc) Quit 1
			;Redirect to main page
			Set %response.Redirect = ..%ClassName(1)_".cls"
		}
		If %request.Get("msg") = "sok" Set Message = "Save of project data successful."
		If %request.Get("msg") = "eok" Set Message = "Export of project successful."
		
	} ElseIf Page = "Import" {
		Set %response.Timeout = 600
		Set %response.Expires = 0 ;Don't cache item list
		If %request.Get("msg") = "lok" Set Message = "Import of project successful."
		;Actual import moved to OnPage because it took too long.
		
	} ElseIf Page = "" {
		;Main page
		If %request.IsDefined("Save") {
			Set sc = ..SaveCfg(Config)
			If 'sc {
				Set ErrorMsg = ..DecomposeStatus("Error saving configuration object:", sc)
				Quit 1
			}
			;Redirect to self so refresh does no harm
			Set %response.Redirect = ..%ClassName(1)_".cls"
			
		} ElseIf %request.IsDefined("LoadExisting") {
			;Load existing project information
			Set sc = ..LoadProject(Config, .Project)
			If 'sc Set ErrorMsg = ..DecomposeStatus("Error loading project:", sc) Quit 1
			;Redirect to self so refresh does no harm
			Set %response.Redirect = ..%ClassName(1)_".cls"
			
		} Else {
			Do ..CfgToRequest(Config)
		}
	}
	
	Quit 1
}

ClassMethod OnPage() As %Status [ PublicList = (ErrorMsg, Message, Config, Project, Page) ]
{
	If %request.Get("img") '= "" Quit ##class(Strix.SCM.UI.Resources).OnPage()
	
	If ErrorMsg '= "" Quit ..Error(ErrorMsg)
	If Page = "Project" Quit ..Project(Config, Project, Message)
	;If Page = "Import" Quit ..Import(Config, Project, Message)
	
	Set sc = ##class(Strix.SCM.Project).GetAllProjects(.Projects)
	If 'sc Quit ..Error(..DecomposeStatus("Error getting project list:", sc))
	
	Set ShowMembers = 0
	
	Do ..Header("Source control configuration")
	
	&html<<h2>General configuration</h2>
<form method="post" action="">
<table class="DataEntry">
<tr>
  <th>Base directory:</th>
  <td>#(..TextInput("BasePath", 80))#</td>
</tr>
<tr class=Buttons>
  <td colspan=2><input type=submit name=Save value="Save"></td>
</tr>
</table>
</form>

<h2>Projects</h2>

<table class="List">
<tr class="HeaderRow">
  <th></th>
  <th>Name</th>
  <th>GUID</th>
  <th>Subdirectory</th>
>
	If ShowMembers &html<  <th>Members</th>>
	
	&html<<th><a href="?Page=Project&amp;Project=">new</a></th></tr>>
	
	For i = 1:1:Projects.Count() {
		Set Project = Projects.GetAt(i)
		
		Set Class = $Select(i # 2: "OddRow", 1: "EvenRow")
		&html<<tr class="#(Class)#">>
		
		&html<  <td class=Right>#(i)#</td>>
		&html<  <td>#(..EscapeHTML(Project.Name))#</td>>
		&html<  <td>#(..EscapeHTML(Project.GUID))#</td>>
		&html<  <td>#(..EscapeHTML(Project.ProjectPath))#</td>>
		
		If ShowMembers {
			Set Members = ""
			For j = 1:1:Project.Members.Count() {
				If j > 1 Set Members = Members_"<br>"_$$$EOL
				Set Members = Members_..EscapeHTML(Project.Members.GetAt(j))
			}
			&html<  <td>#(Members)#</td>>
		}
		
		&html<  <td><a href="?Page=Project&amp;Project=#(..EscapeURL(Project.%Id()))#">edit</a></td>>
		;&html<  <td><a href="?Page=Import&amp;Project=#(..EscapeURL(Project.%Id()))#">import</a></td>>
		
		&html<</tr>>
	}
	
	&html<</table>>
	
	&html<<form method=post action="">
<h2>Load existing project</h2>
<div id=LoadExisting>
#(..TextInput("LoadExisting", 80))# <input type=submit value="Load">
<p class=Explain>Load configuration information for an existing project.
Specify the path, absolute or relative to the configured base directory,
containing the project's configuration file (e.g., <i>Strix/Strix.scm.cfg</i>
or <i>C:\dev\Strix\Strix.scm.cfg</i>).</p>
</div>
</form>>
	
	Do ..Footer()
	
	Quit $$$OK
}

// =====

/// Displays the Edit Project page
ClassMethod Project(Config As Strix.SCM.Config, Project As Strix.SCM.Project, Message As %String) As %Status
{
	Do ..ProjectToRequest(Project)
	
	Do ..Header("Source control configuration")
	&html<<h2>Project configuration</h2>>
	
	If Message '= "" &html<<div class=Message>#(..EscapeHTML(Message))#</div>>
	
	&html<<form method="post" action="">
<table class="DataEntry">
<tr>
  <th>Name:</th>
  <td>
    #(..TextInput("Name", 40))#
    <p class=Explain>The project name.</p>
  </td>
</tr>
<tr>
  <th>Id:</th>
  <td>#(Project.GUID)#
    <p class=Explain>The project's GUID (assigned on first save).</p>
  </td>
</tr>
<tr>
  <th>Handler</th>
  <td>
    #(..TextInput("Handler", 40))#
    <p class=Explain>The handler class for this project.</p>
  </td>
</tr>
<tr>
  <th>Config file path:</th>
  <td>
    #(..TextInput("ConfigFilePath", 80))#
    <p class=Explain>The path to the configuration file, either absolute or relative to the working copy directory.</p>
  </td>
</tr>
<tr>
  <th>Project path:</th>
  <td>
    #(..TextInput("ProjectPath", 80))#
    <p class=Explain>The subdirectory for this project, either absolute or relative to the working copy directory.</p>
  </td>
</tr>
<tr>
  <th>Release path:</th>
  <td>
    #(..TextInput("ReleasePath", 80))#
    <p class=Explain>The release directory for this project. Optional, to be used by release plugin(s).</p>
  </td>
</tr>
<tr>
  <th>Package subdirectories:</th>
  <td>
    #(..CheckBox("PackageSubdirs"))#
    <p class=Explain>Whether to convert packages to subdirectories on export; e.g., if this
    is set, class Strix.SCM.Project would be exported to .../Strix/SCM/Project.cls.xml,
    instead of .../Strix.SCM.Project.cls.xml.</p>
  </td>
</tr>
<tr>
  <th>Members:</th>
  <td>
    #(..TextArea("Members", 10, 60))#
    <p class=Explain>Specify the project members here. The '*' wildcard is supported.
    Supported item types are .cls (classes), .mac and .int (routines) and .inc (include files).<br>
    A special type is .stg: it saves the stored data for the specified class(es).<br>
    To remove items that are selected by another specification, prefix the
    specification with a "-".<br>
    Examples:</p>
    <ul class=Explain>
      <li>Strix.*.cls (All classes in the Strix top-level package, including subpackages)
      <li>Strix.SCM.Project.stg (The stored data for this class)
      <li>-Strix.Settings.*.cls (Remove classes in package Strix.Settings and below)
    </ul>
  </td>
</tr>
<tr>
  <th>Export UDL:</th>
  <td>
    #(..CheckBox("ExportUDL"))#
    <p class=Explain>Whether to items as UDL (checked) or XML (unchecked).</p>
  </td>
</tr>
<tr>
  <th>Export version:</th>
  <td>
    #(..TextInput("ExportVersion", 15))#
    <p class=Explain>When exporting, what version to export for. Only
    applicable to XML exports; can be used to keep these backwards
    compatible. Specify major.minor, e.g. 2010.1.</p>
  </td>
</tr>
<tr>
  <th>Postprocessors:</th>
  <td>
    #(..TextInput("PostProcessors", 80))#
    <p class=Explain>Comma-separated list of item postprocessors to run on
    export. Available are:</p>
    <ul class=Explain>
      <li>VSCodeCompat: export one final newline too few, as the ObjectScript
          VS Code plugin does
      <li>Iris2Cache: attempt to make the export backwards compatible with
          Caché.
    </ul>
  </td>
</tr>
>
	
	;===== Handler settings:
	
	Set SettingList = Project.GetHandlerSettings()
	If $ListLength(SettingList) {
		&html<<tr><th colspan=2>Handler settings</th></tr>>
	}
	
	For i = 1:1:$ListLength(SettingList) {
		Set Item = $List(SettingList, i)
		Set Name = $List(Item, 1), Type = $List(Item, 2), Origin = $List(Item, 3)
		Set Description = ##class(Strix.SCM.Handler.Base).GetSettingDescription(Origin, Name, 1)
		If Type = "%Boolean" {
			Set InputHtml = ..CheckBox("s:"_Name)
		} Else {
			Set InputHtml = ..TextInput("s:"_Name, 80)
		}
		
		&html<<tr>
  <th>#(Name)#:<br><span class=Origin>#(Origin)#</span></th>
  <td>
    #(InputHtml)#
    <p class=Explain>#(Description)#</p>
  </td>
</tr>>
	}
	
	&html<</table>
<div class=Buttons>
  #(..HiddenInput("Page"))#
  #(..HiddenInput("Project"))#
  <input type=submit name=Save value="Save">>
	
	If Project.%Id() '= "" {
		&html<<input type=submit name=Copy value="Copy">>
		;&html<<input type=submit name=Export value="Export">>
		;&html<<input type=button name=Import value="Import" onclick="document.location='#(..%ClassName(1))#.cls?Page=Import&amp;Project=#(Project.%Id())#'">>
		&html<<input type=submit name=Delete value="Delete" onclick="return Ays();">>
	}
	&html<</div>
</form>
>
	
	Do ..Footer()
	
	Quit $$$OK
}

// =====

ClassMethod Header(Titel As %String = "")
{
	Set System = ..GetSystemText()
	&html<<!DOCTYPE HTML> 

<html>
<head>
<title>#(Titel_" &ndash; "_System)#</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
#(##class(Strix.SCM.UI.Resources).CSS())#
<script type="text/javascript">
function Ays()
{
	return confirm("Are you sure you want to delete this object?");
}
</script>
</head>

<body>

<h1><a href="Strix.SCM.UI.cls"><img id=Logo src="Strix.SCM.UI.Resources.cls?img=start" alt="" title="To startpage"></a>[<span class=sysid>#(System)#</span>] #(Titel)#</h1>

<div id=Contents>
>	
	Quit
}

// =====

ClassMethod CfgToRequest(Config As Strix.SCM.Config)
{
	Do %request.Set("BasePath", Config.BasePath)
	Quit
}

ClassMethod SaveCfg(Config As Strix.SCM.Config) As %Status
{
	Set Config.BasePath = %request.Get("BasePath")
	Set sc = Config.%Save()
	If 'sc Quit sc
	Quit $$$OK
}

ClassMethod ProjectToRequest(Project As Strix.SCM.Project)
{
	Do %request.Set("Name", Project.Name)
	Do %request.Set("ProjectPath", Project.ProjectPath)
	Do %request.Set("ReleasePath", Project.ReleasePath)
	Do %request.Set("ConfigFilePath", Project.ConfigFilePath)
	Do %request.Set("Handler", Project.Handler)
	If Project.PackageSubdirs Do %request.Set("PackageSubdirs", 1)
	If Project.ExportUDL Do %request.Set("ExportUDL", 1)
	Do %request.Set("ExportVersion", Project.ExportVersion)
	Do %request.Set("PostProcessors", Project.PostProcessors)
	
	Set Members = ""
	For i = 1:1:Project.Members.Count() {
		Set Members = Members_Project.Members.GetAt(i)_$Char(13, 10)
	}
	Do %request.Set("Members", Members)
	
	Set SettingList = Project.GetHandlerSettings()
	For i = 1:1:$ListLength(SettingList) {
		Set Item = $List(SettingList, i), Name = $List(Item, 1), Type = $List(Item, 2), Global = $List(Item, 4)
		Set Value = $Select(Global: Project.Settings.GetAt(Name), 1: Project.LocalSettings.GetAt(Name))
		If Type = "%Boolean" {
			If Value Do %request.Set("s:"_Name, 1)
		} Else {
			Do %request.Set("s:"_Name, Value)
		}
	}
	
	Quit
}

ClassMethod SaveProject(Config As Strix.SCM.Config, Project As Strix.SCM.Project) As %Status
{
	Set Project.Name = %request.Get("Name")
	Set Project.Handler = %request.Get("Handler")
	Set Project.ConfigFilePath = %request.Get("ConfigFilePath")
	Set Project.ProjectPath = %request.Get("ProjectPath")
	Set Project.ReleasePath = %request.Get("ReleasePath")
	Set Project.PackageSubdirs = ''%request.IsDefined("PackageSubdirs")
	Set Project.ExportUDL = ''%request.IsDefined("ExportUDL")
	Set Project.ExportVersion = %request.Get("ExportVersion")
	Set Project.PostProcessors = %request.Get("PostProcessors")
	
#;	;Make sure the project's directory exists
#;	If ##class(Strix.Lib.File).IsPathAbsolute(Project.ProjectPath) {
#;		Set Path = Project.ProjectPath
#;	} Else {
#;		Set Path = ##class(Strix.Lib.File).AppendPath(Config.BasePath, Project.ProjectPath)
#;	}
#;	If '##class(%File).DirectoryExists(Path) {
#;		Quit $$$BuildErr("Project directory '{}' does not exist; please create it first.",, Path)
#;	}
	
	#dim Handlers As %ListOfDataTypes
	Set sc = ##class(Strix.SCM.HandlerProxy).GetHandlers(.Handlers)
	If 'sc Quit $$$BuildErr("Error retrieving list of available handlers:", sc)
	If 'Handlers.Find(Project.Handler) Quit $$$BuildErr("No such handler: "_Project.Handler)
	
	;Check config file
	Set ConfigFilePath = Project.ConfigFilePath
	If ConfigFilePath '= "", '##class(Strix.Lib.File).IsPathAbsolute(ConfigFilePath) {
		Set ConfigFilePath = ##class(%File).SubDirectoryName(Config.BasePath, ConfigFilePath)
	}
	
	;New project: do not overwrite an existing one.
	If Project.%Id() = "", ##class(%File).Exists(ConfigFilePath) {
		Quit $$$BuildErr("A project configuration file already exists at '{}'.",, Project.ConfigFilePath)
	}
	
	Set Members = %request.Get("Members")
	Do Project.Members.Clear()
	For i = 1:1:$Length(Members, $Char(13, 10)) {
		Set Member = $ZStrip($Piece(Members, $Char(13, 10), i), "<>W")
		If Member = "" Continue
		Do Project.Members.Insert(Member)
	}
	
	Do Project.Settings.Clear()
	Do Project.LocalSettings.Clear()
	Set SettingList = Project.GetHandlerSettings()
	For i = 1:1:$ListLength(SettingList) {
		Set Item = $List(SettingList, i), Name = $List(Item, 1), Type = $List(Item, 2), Global = $List(Item, 4)
		Set Value = %request.Get("s:"_Name)
		If Value = "" Continue
		If Global {
			Do Project.Settings.SetAt(Value, Name)
		} Else {
			Do Project.LocalSettings.SetAt(Value, Name)
		}
	}
	
	Set sc = Project.%Save()
	If 'sc Quit sc
	
	Quit $$$OK
}

ClassMethod LoadProject(Config As Strix.SCM.Config, Output Project As Strix.SCM.Project) As %Status
{
	Set SubPath = %request.Get("LoadExisting")
	If SubPath = "" Quit $$$ERROR($$$GeneralError, "No project path specified.")
	
	;Support "Copy as path" explorer context menu by stripping quotes if present
	If $Extract(SubPath) = """", $Extract(SubPath, *) = """" Set SubPath = $Extract(SubPath, 2, *-1)
	
	If ##class(Strix.Lib.File).IsPathAbsolute(SubPath) {
		Set Path = SubPath
	} Else {
		Set Path = ##class(%File).SubDirectoryName(Config.BasePath, SubPath)
	}
	If '##class(%File).Exists(Path) Quit $$$BuildErr("No project configuration file found in '{}'.",, Path)
	
	Set sc = ##class(Strix.SCM.Project).LoadProjectFileData(Path, .Project)
	If 'sc Quit sc
	
	Set Check = ##class(Strix.SCM.Project).%OpenId(Project.GUID, , .sc)
	If sc Quit $$$BuildErr("A project ({}) is already defined with id {}.",, Check.Name, Project.GUID)
	
	Set sc = ##class(Strix.SCM.Project).LoadProjectFile(Path)
	If 'sc Quit sc
	
	Quit $$$OK
}

ClassMethod DeleteProject(Project As Strix.SCM.Project) As %Status
{
	If Project.%Id() = "" Quit $$$OK
	Set sc = Project.%DeleteId(Project.%Id())
	If 'sc Quit sc
	Quit $$$OK
}

// =====

ClassMethod Error(ErrorMsg As %String) As %Status
{
	Set System = ..GetSystemText()
	&html<<!DOCTYPE HTML> 

<html>
<head>
<title>Fout</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
#(##class(Strix.SCM.UI.Resources).CSS())#
</head>

<body>

<h1><a href="Strix.SCM.UI.cls"><img id=Logo src="Strix.SCM.UI.Resources.cls?img=start" alt="" title="To startpage"></a>[<span class=sysid>#(System)#</span>] An error has occurred.</h1>

<div id=Contents>
<div class=ErrorMsg>
#(ErrorMsg)#
</div>

</div>
</body>
</html>
>
	
	Quit $$$OK
}

ClassMethod Footer()
{
	&html<</div>
</body>
</html>
>
	Quit
}

/// Returns a system identifier consisting of system name, instance name, namespace.
ClassMethod GetSystemText() As %String
{
	Set System = $ZUtil(86)
	If System["*" Set System = $Piece(System, "*", 2)
	Set System = ##class(%Function).HostName()_":"_System_":"_$ZUtil(5)
	Quit System
}

}
