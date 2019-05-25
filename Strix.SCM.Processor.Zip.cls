<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.SCM.Processor.Zip">
<Description>
Zips the release directory.</Description>
<Super>Strix.SCM.Processor.Base</Super>
<TimeCreated>64374,53782.637984</TimeCreated>

<Parameter name="HandlerType">
<Description>
This processor works on a release.</Description>
<Default>Release</Default>
</Parameter>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="Run">
<FormalSpec>Revision:%String,Directory:%String</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Set Status = ..ZipDir(Directory, 1)
	If 'Status Quit Status
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ZipDir">
<ClassMethod>1</ClassMethod>
<FormalSpec>Directory:%String,Delete:%Boolean=0</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>
</Class>
</Export>
