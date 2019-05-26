/// Zips the release directory.
Class Strix.SCM.Processor.Zip Extends Strix.SCM.Processor.Base
{

/// This processor works on a release.
Parameter HandlerType = "Release";

// =====

Method Run(Revision As %String, Directory As %String) As %Status
{
	Set Status = ..ZipDir(Directory, 1)
	If 'Status Quit Status
	
	Quit $$$OK
}

ClassMethod ZipDir(Directory As %String, Delete As %Boolean = 0) As %Status
{
	Set Executable = "C:\Program Files\7-Zip\7z.exe"
	Set Executable = ##class(%File).NormalizeFilenameWithSpaces(Executable)
	
	Do ##class(Strix.Lib.File).SplitPath(Directory, .BaseDir, .ReleaseDir)
	Set ZipFile = ##class(%File).SubDirectoryName(BaseDir, ReleaseDir_".zip")
	
	Set Command = Executable_" "_"a """_ZipFile_""" """_Directory_""""
	Set Result = ##class(Strix.Lib.IO).GetCommandOutput(Command, , .ErrorMsg)
	If ErrorMsg '= "" Quit $$$BuildErr("Error running command '{}': {}",, Command, ErrorMsg)
	
	Set Lines = ##class(Strix.Lib.String).SplitLines(Result, , 1)
	If 'Lines.Count() || (Lines.GetAt(Lines.Count()) '= "Everything is Ok") {
		Quit $$$BuildErr("Error from zip: {}", , Result)
	}
	
	If 'Delete Quit $$$OK
	
	Set rc = ##class(%File).RemoveDirectoryTree(Directory)
	If 'rc Quit $$$BuildErr("Error {} removing directory.",, rc)
	
	Quit $$$OK
}

}

