/// Removes the SCM configuration file from the release.
Class Strix.SCM.Processor.RemoveCfgFile Extends Strix.SCM.Processor.Base
{

/// This processor works on a release.
Parameter HandlerType = "Release";

// =====

Method Run(Revision As %String, Directory As %String) As %Status
{
	Set ConfigFileName = ##class(%File).GetFilename(..Project.ConfigFilePath)
	Set ConfigFilePath = ##class(%File).SubDirectoryName(Directory, ConfigFileName)
	
	; Windows 10 Version 10.0.16299: sometimes file appears not there
	; (yet). Wait a while to be sure.
	For i = 1:1:5 Hang 1 If ##class(%File).Exists(ConfigFilePath) Quit
	
	If '##class(%File).Exists(ConfigFilePath) {
		Quit $$$BuildErr("Error: configuration file '{}' not found.", , ConfigFilePath)
	}
	
	Do ..Write("Removing config file "_ConfigFilePath)
	Set rc = ##class(%File).Delete(ConfigFilePath, .ec)
	If 'rc Quit $$$BuildErr("Error {} deleting {}.", , ec, ConfigFilePath)
	
	Quit $$$OK
}

}
