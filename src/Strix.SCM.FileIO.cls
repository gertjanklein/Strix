Include Strix.SCM

/// Export/import code
Class Strix.SCM.FileIO Extends %RegisteredObject
{

/// The file handler that's calling us
Property Handler As Strix.SCM.Handler.File;

/// The project we're working with
Property Project As Strix.SCM.Project;

/// The item we're working with
Property Item As %String;

// =====

/// Exports a single item to disk
Method ExportItem(Output Filename As %String) As %Status
{
	Set Filename = ..Project.GetExportFilename(..Item, , , .Status)
	If 'Status Quit Status
	
	Set Processors = ..Project.GetProcessors(.Status)
	If 'Status Quit $$$BuildStatus("Error determining list of post-processors for project:", Status)
	
	Set Status = ..Export(..Item, ..Project.ExportUDL, Processors, Filename)
	If 'Status Quit $$$BuildStatus("Error exporting '{}':", Status, ..Item)
	
	Quit $$$OK
}

/// Exports data for a class to disk
Method ExportClassData(Output Filename As %String) As %Status
{
	;Item is a class; we must change type to stg for filename.
	Set ClassName = ..Item
	Set $Piece(Item, ".", $Length(..Item, ".")) = "stg"
	
	Set Filename = ..Project.GetExportFilename(Item, , , .Status)
	If 'Status Quit Status
	
	Set Globals = ##class(Strix.SCM.Matcher).GetStorageGlobals(ClassName, .Status)
	If 'Status Quit Status
	
	Set Processors = ..Project.GetProcessors(.Status)
	If 'Status Quit $$$BuildStatus("Error determining list of post-processors for project:", Status)
	
	Set Status = ..Export(Globals, 0, Processors, Filename)
	If 'Status Quit $$$BuildStatus("Error exporting '{}':", Status, Item)
	
	Quit $$$OK
}

/// Loads a single item from disk
Method LoadItem(Output Filename As %String) As %Status
{
	Set Filename = ..Project.GetExportFilename(..Item, , , .Status)
	If 'Status Quit Status
	
	Set Status = ..Import(Filename, ..Item)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Loads data for a class from disk
Method LoadClassData(Output Filename As %String) As %Status
{
	;Item is a class; we must change type to stg for filename.
	Set ClassName = ..Item, Item = ..Item
	Set $Piece(Item, ".", $Length(Item, ".")) = "stg"
	
	Set Filename = ..Project.GetExportFilename(Item, , , .Status)
	If 'Status Quit Status
	
	Set Globals = ##class(Strix.SCM.Matcher).GetStorageGlobals(ClassName, .Status)
	If 'Status Quit Status
	
	Set Status = ..Import(Filename, Globals, "-d")
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Exports an entire project to disk
Method ExportProject(Quiet As %Boolean = 0) As %Status
{
	If 'Quiet Write "Determining project members: "
	Set Status = ..Project.GetAllItems(.Items)
	If 'Status Quit $$$BuildErr("Error determining project members", Status)
	If 'Quiet Write "ok",!
	
	Set Processors = ..Project.GetProcessors(.Status)
	If 'Status Quit $$$BuildStatus("Error determining list of post-processors for project:", Status)
	
	Set Item = ""
	For  {
		Set Item = $Order(Items(Item), 1, Members)
		If Item = "" Quit
		
		Set Filename = ..Project.GetExportFilename(Item, , , .Status)
		If 'Status Quit
		
		If Members = "" Set Members = Item
		If 'Quiet Write "Exporting "_Members_" to "_Filename_": "
		
		Set Status = ..Export(Members, ..Project.ExportUDL, Processors, Filename)
		If 'Status Return $$$BuildStatus("Error exporting '{}':", Status, Item)
		
		If 'Quiet Write "ok",!
	}
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Loads all project members form the configured directory
Method ImportProject(Quiet As %Boolean = 0) As %Status
{
	;Get list of XML files in the project directory
	If 'Quiet Write !,"== Reading directory: "
	Set stm = ##class(%SQL.Statement).%New()
	Set sc = stm.%PrepareClassQuery("%File","FileSet")
	If 'sc Quit $$$BuildErr("Error preparing FileSet query:", sc)
	
	If ..Project.ExportUDL {
		Set FileSpec = "*.cls;*.inc"
	} Else {
		Set FileSpec = "*.xml"
	}
	
	#dim rs As %SQL.StatementResult
	Set rs = stm.%Execute(..Project.GetProjectPath(), FileSpec)
	
	While rs.%Next() {
		Set Name = rs.%Get("Name")
		Set ItemName = rs.%Get("ItemName")
		Set Files(ItemName) = Name
	}
	Kill rs
	If 'Quiet Write "ok",!
	
	Set ItemName = ""
	For  {
		Set ItemName = $Order(Files(ItemName), 1, FullPath)
		If ItemName = "" Quit
		
		Write "Importing "_ItemName_": "
		
		Set sc = $System.OBJ.Load(FullPath, "-d", , .FileItems)
		Merge Loaded = FileItems
		
		Write "ok.",!
	}
	
	If 'Quiet Write !,"Compiling: "
	Set sc = $System.OBJ.CompileList(.Loaded, "cku-d")
	If 'sc Quit $$$BuildErr("Error compiling loaded items:", sc)
	If 'Quiet Write "ok",!
	
	Quit $$$OK
}

/// Exports an item, running post-processors if configured.
Method Export(Item As %String, AsUDL As %Boolean, Processors As %ListOfObjects, Filename As %String) As %Status
{
	Set Stream = ##class(%Stream.FileBinary).%New()
	
	; Make sure stream has a filename
	Set sc = Stream.Write("")
	If 'sc Quit $$$BuildStatus("Error creating temporary stream for output:", Status)
	
	; Export to it
	If AsUDL {
		Set sc = $System.OBJ.ExportUDL(Item, Stream.Filename, "-d/diffexport")
	} Else {
		Set Version = ..Project.ExportVersion
		If Version '= "" Set Version = "/exportversion="_Version
		Set sc = $System.OBJ.Export(Item, Stream.Filename, "-d/diffexport"_Version)
	}
	If 'sc Quit $$$BuildStatus("Error exporting {}:", sc, Item)
	
	; Call processors in order
	For i = 1:1:Processors.Count() {
		#dim Processor As Strix.SCM.Processor.Base
		Set Processor = Processors.GetAt(i)
		
		Set Stream = Processor.ProcessExport(Item, Stream, .sc)
		If 'sc Return $$$BuildStatus("Error processing '{}':", sc, Item)
	}
	
	; Make sure output directory exists
	Set sc = ##class(Strix.Lib.File).EnsureDirectory(Filename)
	If 'sc Quit $$$BuildStatus("Error exporting {}:", sc, Item)
	
	; Save resulting data to 
	Set Output = ##class(%Stream.FileBinary).%New()
	Set sc = Output.LinkToFile(Filename)
	If 'sc Return $$$BuildStatus("Error opening export file '{}':", sc, Filename)
	Set sc = Output.CopyFromAndSave(Stream)
	If 'sc Return $$$BuildStatus("Error saving export data to '{}':", sc, Filename)
	
	Quit $$$OK
}

Method Import(Filename As %String, Item As %String, Flags As %String = "ckd") As %Status
{
	If ..Project.ExportUDL {
		; Don't specify the item to load. The file can only contain one
		; anyway, and if the item type is uppercase (e.g. My.Class.CLS),
		; as is is by default, the load gives no errors but does nothing.
		Set Status = $System.OBJ.Load(Filename, Flags)
	} Else {
		Set Status = $System.OBJ.Load(Filename, Flags, , , , Item)
	}
	If 'Status Quit $$$BuildErr("Error loading '{}' from '{}'", Status, Item, Filename)
	
	Quit $$$OK
}

}

