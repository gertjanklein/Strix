Include Strix.SCM

/// Configuration of the source control interface. Defines a single project;
/// multiple projects may be present in a single namespace. This information
/// itself is (partly) versioned as well.
Class Strix.SCM.Project Extends (%Persistent, %XML.Adaptor)
{

// ===== ID

/// The GUID of this project; assigned on first creation of the project. Used to
/// make sure the proper file is loaded / saved to.
Property GUID As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

// ===== Local information not present in configuration file

/// The location of the external configuration file.
Property ConfigFilePath As %String(MAXLEN = 512, XMLPROJECTION = "NONE");

// ===== Global information from configuration file

/// The project name.
Property Name As %String [ Required ];

/// The path, relative to the configuration file directory, where to store the
/// exported classes etc.; can be empty for same directory as that of config file.
Property ProjectPath As %String;

/// The members of this project, defined as a list of 'patterns' supporting
/// wildcards. Examples:
/// Strix.*.cls (all classes in the Strix package)
/// Strix.SCM.*.gbl (all globals starting with the specified string)
/// Patterns can be turned into "exclude" patterns by prefixing them with a "-".
Property Members As list Of %String(MAXLEN = 256, STORAGEDEFAULT = "array", XMLITEMNAME = "Spec");

/// Whether to convert packages to subdirectories on export; e.g., if this
/// is set, class Strix.SCM.Project would be exported to .../Strix/SCM/Project.cls.xml,
/// instead of .../Strix.SCM.Project.cls.xml
Property PackageSubdirs As %Boolean [ InitialExpression = 0 ];

/// Classname of handler for this project
Property Handler As %String;

/// Whether to export items as XML (0) or CDL (1)
Property ExportUDL As %Boolean [ InitialExpression = 0 ];

/// When exporting, what version to export for. Can be used to keep
/// exports backwards compatible. Only applies to XML exports.
Property ExportVersion As %String;

/// Comma-separated list of export item post-processors to run.
Property PostProcessors As %String(MAXLEN = 80);

// =====

/// Handler-specific settings for this project
Property Settings As array Of %String(MAXLEN = "", XMLITEMNAME = "Setting", XMLKEYNAME = "Name");

/// Local handler settings (not stored in the configuration file)
Property LocalSettings As array Of %String(MAXLEN = "", XMLPROJECTION = "NONE");

// =====

Index IdKey On GUID [ IdKey, Unique ];

Index OnName On Name [ Unique ];

// =====

/// Loads a configuration file. If the corresponding Project object
/// already exists, it is updated; otherwise, a new one is created.
/// Saves the created/updated project.
ClassMethod LoadProjectFile(FileName As %String, Output Project As Strix.SCM.Project) As %Status
{
	Set sc = ..LoadProjectFileData(FileName, .ProjectFromFile)
	If 'sc Quit sc
	
	Set Existing = ..%ExistsId(ProjectFromFile.GUID)
	If Existing {
		;Update properties of exiting object
		Set Project = ..%OpenId(ProjectFromFile.GUID, , .Status)
		If 'Status Quit $$$BuildErr("Error opening existing project '{}'", Status, ProjectFromFile.GUID)
		Do Project.CopyFrom(ProjectFromFile)
	} Else {
		Set Project = ProjectFromFile
	}
	
	;Save last filename
	Set Project.ConfigFilePath = FileName
	
	Set Status = Project.%Save()
	If 'Status Quit $$$BuildErr("Error "_$Select(Existing: "updating", 1: "creating")_" project object", Status)
	
	Quit $$$OK
}

/// Loads data from a project file, without altering anything.
ClassMethod LoadProjectFileData(FileName As %String, Output Project As Strix.SCM.Project) As %Status
{
	Set Reader = ##class(%XML.Reader).%New()
	Set Status = Reader.OpenFile(FileName)
	If 'Status Quit $$$BuildErr("Error opening project configuration file '{}':", Status, FileName)
	
	Do Reader.CorrelateRoot(..%ClassName(1))
	If 'Reader.Next(.Project, .Status) {
		If Status Quit $$$BuildErr("No configuration data found in '{}'.",, FileName)
		Quit $$$BuildErr("Error correlating data in '{}' to the Project class.", Status, FileName)
	}
	
	Quit $$$OK
}

/// Saves the configuration, in XML format, to the file specified in
/// property ConfigFilePath.
Method SaveProjectFile() As %Status
{
	Set ConfigFilePath = ..ConfigFilePath
	If '##class(Strix.Lib.File).IsPathAbsolute(ConfigFilePath) {
		Set ProjectPath = ..GetProjectPath(.sc)
		If 'sc Quit sc
		Set ConfigFilePath = ##class(%File).SubDirectoryName(ProjectPath, ConfigFilePath)
	}
	
	Set File = ##class(%FileCharacterStream).%New()
	Set File.Filename = ConfigFilePath
	
	Set Status = ..XMLExportToStream(File, , ",indent")
	If 'Status Quit $$$BuildErr("Error exporting project configuration to XML:", Status)
	
	Set Status = File.SaveStream()
	If 'Status Quit $$$BuildErr("Error saving configuration to '"_..ConfigFilePath_"':", Status)
	
	Quit $$$OK
}

/// Copies properties from another Project instance into the current one.
Method CopyFrom(Other As Strix.SCM.Project) [ CodeMode = objectgenerator ]
{
	#define Write(%s) Do %code.WriteLine($Char(9)_%s)
	
	For i = 1:1:%class.Properties.Count() {
		#dim PropDef As %Dictionary.PropertyDefinition
		Set PropDef = %class.Properties.GetAt(i)
		
		Set Name = PropDef.Name
		If $Extract(Name) = "%" Continue
		If Name = "GUID" Continue
		If PropDef.Calculated Continue
		If PropDef.Parameters.GetAt("XMLPROJECTION") = "NONE" Continue
		
		If PropDef.Collection = "" {
			$$$Write("Set .."_Name_" = Other."_Name)
		} ElseIf (PropDef.Collection = "list") || (PropDef.Collection = "array") {
			$$$Write("Set .."_Name_" = Other."_Name_".%ConstructClone()")
		}
	}
	
	$$$Write("Quit")
	
	Quit $$$OK
}

/// Called by the system after the project object has been saved; used to update
/// the configuration file in the working copy.
Method %OnAfterSave(Insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	; If we're not using a config file, we're done
	If ..ConfigFilePath = "" Quit $$$OK
	
	;If this is an insert and a config file already exists, we're loading that file.
	;In this case, don't overwrite the file.
	If Insert, ##class(%File).Exists(..ConfigFilePath) Quit $$$OK
	
	;Export the information the the configuration file
	Set Status = ..SaveProjectFile()
	If 'Status Quit Status
	
	Quit $$$OK
}

// =====

/// Returns the appropriate handler for the document specified in
/// parameter InternalName, initialized with the project's settings.
ClassMethod GetHandler(InternalName As %String = "", Output Handler As Strix.SCM.Handler.Base) As %Status
{
	;Initialise the handler to the do-nothing base, in case not specified
	Set Handler = ##class(Strix.SCM.Handler.Base).%New()
	
	;Determine which project(s), if any, own this item
	Set ProjectIds = ..GetProjectsOwningItem(InternalName, .Status)
	If 'Status Quit $$$BuildErr("Error determining projects owning '"_InternalName_"':", Status)
	
	;We need exactly one project
	If $ListLength(ProjectIds) '= 1 {
		If $ListLength(ProjectIds) > 1 Write !,"=== More than one project owns this item; this is not supported."
		Quit ##class(Strix.SCM.Handler.Base).%New()
	}
	
	;Open project
	Set ProjectId = $List(ProjectIds)
	Set Project = ##class(Strix.SCM.Project).%OpenId(ProjectId, , .Status)
	If 'Status Quit $$$BuildErr("Error opening project '"_ProjectId_"' for '"_InternalName_"':", Status)
	
	;Determine handler class
	Set HandlerClass = Project.Handler
	If HandlerClass = "" {
		Write !,"This project doesn't have a handler specified.",!
		Quit $$$OK
	}
	
	;Create instance
	Try {
		Set Handler = $ZObjClassMethod(HandlerClass, "%New")
	} Catch e {
		Set Status = $$$BuildErr("Error opening handler class '"_HandlerClass_"' instance:", e.AsStatus())
	}
	If 'Status Quit Status
	
	;Get and apply settings
	For Collection = Project.Settings, Project.LocalSettings {
		Set Name = ""
		For  {
			Set Value = Collection.GetNext(.Name)
			If Name = "" Quit
			Set $ZObjProperty(Handler, Name) = Value
		}
	}
	
	If Handler.%IsA("Strix.SCM.Handler.File") {
		; Create an instance of the class handling file IO:
		If 'Handler.RemoteFileIO {
			Set Handler.FileIO = ##class(Strix.SCM.FileIO).%New()
		} Else {
			Set Handler.FileIO = ##class(Strix.SCM.RemoteFileIO).%New()
		}
		Set Handler.FileIO.Handler = Handler
		Set Handler.FileIO.Project = Project
		Set Handler.FileIO.Item = InternalName
	}
	
	Quit Handler
}

Method GetProcessors(Output Status As %Status) As %ListOfObjects
{
	Set Status = $$$OK
	
	Set Processors = ##class(%ListOfObjects).%New()
	Set Names = $ZStrip(..PostProcessors, "<>W")
	If Names = "" Quit Processors
	
	For i = 1:1:$Length(Names, ",") {
		Set ClassName = $ZStrip($Piece(Names, ",", i), "<>W")
		If ClassName = "" Continue
		
		If ClassName '[ ".", ##class(%Dictionary.ClassDefinition).%ExistsId("Strix.SCM.Processor."_ClassName) {
			Set ClassName = "Strix.SCM.Processor."_ClassName
		}
		
		Set Processor = ##class(Strix.SCM.Processor.Base).Get(ClassName, "", $this, .Status)
		If 'Status Return ""
		
		Do Processors.Insert(Processor)
	}
	
	Quit Processors
}

/// Retrieves a list of valid settings for the currently configured handler.
Method GetHandlerSettings() As %List
{
	Set Handler = ..Handler
	If Handler = "" Quit ""
	Set Settings = $ZObjClassMethod(Handler, "GetSettings")
	Quit Settings
}

// =====

/// Returns the basic storage path for files managed by this project
Method GetProjectPath(Output Status As %Status) As %String
{
	Set Status = $$$OK
	
	;Get configured path (may be empty)
	Set ProjectPath = ..ProjectPath
	;If it appears a template, substitute namespace and current system
	If ProjectPath [ "{" Set ProjectPath = ##class(Strix.Lib.String).TemplateReplace(ProjectPath, $ZUtil(5), $ZUtil(110))
	
	;If this is an absolute path we're done
	If ##class(Strix.Lib.File).IsPathAbsolute(ProjectPath) Quit ProjectPath
	
	;Get base path for relative path
	Set Config = ##class(Strix.SCM.Config).Get()
	
	;Create full path
	Set ProjectPath = ##class(Strix.Lib.File).AppendPath(Config.BasePath, ProjectPath)
	
	Quit ProjectPath
}

/// Returns the file name for an item, based on project settings.
Method GetExportFilename(ItemName As %String, Output Directory As %String, Output Filename As %String, Output Status As %Status) As %String
{
	Set (Directory, FileName) = ""
	
	Set Path = ..GetProjectPath(.Status)
	If 'Status Quit ""
	
	Set Name = $$$ItemName(ItemName)
	Set Type = $$$NormalizedType(ItemName)
	If "bpl,dtl" [ Type Set Type = "cls"
	
	If ..PackageSubdirs {
		Do ##class(Strix.Lib.String).Explode(Name, ".", .Pieces)
		Set Filename = Pieces(Pieces)
		Set Pieces = Pieces - 1
		Set Directory = ##class(Strix.Lib.File).AppendPath(Path, Pieces...)
		
	} Else {
		Set Directory = Path
		Set Filename = Name
	}
	
	Set Filename = Filename_"."_Type
	If '..ExportUDL Set Filename = Filename_".xml"
	
	Set FullPath = ##class(Strix.Lib.File).AppendPath(Directory, Filename)
	
	Quit FullPath
}

// =====

/// Returns a boolean indicating whether this item is handled by a project.
ClassMethod CheckItem(ByRef Item As %String, Output Project As Project, Output AsItem As %Boolean, Output AsStorage As %Boolean, Output Msg As %String) As %Boolean
{
	Set (Project, Msg) = "", (AsItem, AsStorage) = 0
	
	;Normalize name:
	$$$NormalizeType(Item)
	
	;We currently only support the types below
	Set Type = $$$ItemType(Item)
	If '$ListFind($ListFromString("cls,bpl,dtl,mac,int,inc"), Type) Quit 0
	
	;Get id of project owning this item:
	Set ProjectIds = ..GetProjectsOwningItem(Item, .Status)
	If 'Status Set Msg = "Error determining project for '"_Item_"'." Quit 0
	If ProjectIds = "" Quit 0
	
	;Make sure only one project owns this item
	If $ListLength(ProjectIds) > 1 {
		;ToDo: get names of these projects for display in message
		Set Msg = "Error: multiple projects own '"_Item_"'."
		Quit 0
	}
	
	;Open project object:
	Set Project = ##class(Strix.SCM.Project).%OpenId($List(ProjectIds), , .Status)
	If 'Status {
		Set Msg = "Error opening project: "_$System.Status.GetErrorText(Status)
		Quit 0
	}
	
	;Call OwnsItem to get AsItem and AsStorage;
	Do Project.OwnsItem(Item, .AsItem, .AsStorage)
	
	Quit 1
}

/// Returns a boolean indicating whether this project handles the specified
/// item. Also returns two booleans indicating whether the item itself is
/// handled, and whether the item's storage is handled. (The method returns
/// true if either one of these booleans is true.)
Method OwnsItem(Item As %String, Output AsItem As %Boolean, Output AsStorage As %Boolean) As %Boolean
{
	Set Matcher = ##class(Matcher).%New(..Members)
	Quit Matcher.Matches(Item, .AsItem, .AsStorage)
}

/// Returns an array of all items in the current namespace that match
/// the project's member specifications.
Method GetAllItems(Output Items) As %Status
{
	Set Matcher = ##class(Matcher).%New(..Members)
	Set Status = Matcher.GetAllMembers(.Items)
	If 'Status Quit Status
	Quit $$$OK
}

// =====

/// Open and return the project with the specified name, if present.
ClassMethod FindByName(ProjectName As %String, Output Project As Strix.SCM.Project) As %Status
{
	&sql(SELECT %ID, COUNT(*) INTO :ProjectId, :Count FROM Project WHERE Name = :ProjectName)
	If SQLCODE Quit $$$BuildErr("No project with name '"_ProjectName_"' found.", $$$ERROR($$$SQLError, SQLCODE, $Get(%msg)))
	
	If Count > 1 Quit $$$BuildErr("Multiple projects with name '"_ProjectName_"' found.", 1)
	
	Set Project = ..%OpenId(ProjectId, , .sc)
	If 'sc Quit $$$BuildErr("Error opening project with id '"_ProjectId_"':", sc)
	
	Quit $$$OK
}

/// Returns a list of ids of projects owning this item.
ClassMethod GetProjectsOwningItem(Item As %String, Output Status As %Status) As %List
{
	Set rs = ##class(%ResultSet).%New(..%ClassName(1)_":ProjectsOwningItem")
	If 'rs Set Status = $$$BuildErr("Error creating project query", $Get(%objlasterror)) Quit ""
	
	Set Status = rs.Execute(Item)
	If 'Status Set Status = $$$BuildErr("Error executing project query", Status) Quit ""
	
	Set Result = ""
	While rs.Next() {
		Set Id = rs.Get("ID")
		Set Result = Result_$ListBuild(Id)
	}
	
	Quit Result
}

// =====

/// Returns all projects in this namespace.
ClassMethod GetAllProjects(Output Projects As %ListOfObjects = "") As %Status
{
	If Projects = "" {
		Set Projects = ##class(%ListOfObjects).%New()
	} Else {
		Do Projects.Clear()
	}
	
	Set rs = ##class(%ResultSet).%New(..%ClassName(1)_":Projects")
	If '$IsObject(rs) Quit $$$BuildErr("Error creating Projects query", $Get(%objlasterror))
	Set sc = rs.Execute()
	If 'sc Quit $$$BuildErr("Error executing Projects query", sc)
	
	While rs.Next() {
		Set Project = rs.GetObject()
		Do Projects.Insert(Project)
	}
	
	Quit $$$OK
}

// =====

/// Returns all known projects
Query Projects() As %SQLQuery
{
SELECT ID, Name
  FROM Project
 ORDER BY Name
}

/// Returns the id and name of all project owning an item.
Query ProjectsOwningItem(Item As %String) As %Query(CONTAINID = 1, ROWSPEC = "ID:%String,Name:%String") [ SqlProc ]
{
}

ClassMethod ProjectsOwningItemExecute(ByRef qHandle As %Binary, Item As %String) As %Status
{
	Set Node = $Name(^||Projects($Increment(^||Projects)))
	Set qHandle = $lb(Item, Node, "")
	
	;Get resultset for all projects
	Set rs = ##class(%ResultSet).%New(..%ClassName(1)_":Projects")
	Set sc = rs.Execute()
	If 'sc Quit $$$BuildErr("Error executing Projects query:", sc)
	
	While rs.Next() {
		Set Id = rs.Get("ID")
		Set Name = rs.Get("Name")
		
		;Check if this one has a member spec covering this item
		Set Project = ..%OpenId(Id, , .sc)
		If 'sc Continue
		If 'Project.OwnsItem(Item) Continue
		
		;Store in temp global for Fetch to pick up
		Set Key = $ZConvert(Name, "U")_Id
		Set @Node@(Key) = $lb(Id, Name)
	}
	
	Do rs.Close()
	
	Quit $$$OK
}

ClassMethod ProjectsOwningItemFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = OwnsItemExecute ]
{
	Set Item = $li(qHandle, 1), Node = $li(qHandle, 2), Key = $li(qHandle, 3)
	
	Set Key = $Order(@Node@(Key), 1, Data)
	If Key = "" {
		Set Row = ""
		Set AtEnd = 1
		Quit $$$OK
	}
	
	Set $li(qHandle, 3) = Key
	Set Row = Data
	Set AtEnd = 0
	
	Quit $$$OK
}

ClassMethod ProjectsOwningItemClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = OwnsItemExecute ]
{
	Set Node = $li(qHandle, 2)
	Kill @Node
	Quit $$$OK
}

// =====

Storage Default
{
<Data name="LocalSettings">
<Attribute>LocalSettings</Attribute>
<Structure>subnode</Structure>
<Subscript>"LocalSettings"</Subscript>
</Data>
<Data name="Members">
<Attribute>Members</Attribute>
<Structure>subnode</Structure>
<Subscript>"Members"</Subscript>
</Data>
<Data name="ProjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ConfigFilePath</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>ProjectPath</Value>
</Value>
<Value name="5">
<Value>PackageSubdirs</Value>
</Value>
<Value name="6">
<Value>Handler</Value>
</Value>
<Value name="7">
<Value>Settings</Value>
</Value>
<Value name="8">
<Value>ExportUDL</Value>
</Value>
<Value name="9">
<Value>PostProcessors</Value>
</Value>
<Value name="10">
<Value>ExportVersion</Value>
</Value>
</Data>
<DataLocation>^Strix.SCM.ProjectD</DataLocation>
<DefaultData>ProjectDefaultData</DefaultData>
<IdLocation>^Strix.SCM.ProjectD</IdLocation>
<IndexLocation>^Strix.SCM.ProjectI</IndexLocation>
<StreamLocation>^Strix.SCM.ProjectS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

