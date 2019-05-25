/// Moves Ensemble Production classes to a subdirectory "Productions".
Class Strix.SCM.Processor.EnsProdDir Extends Strix.SCM.Processor.Base
{

/// This processor works on a release.
Parameter HandlerType = "Release";

// =====

Method Run(Revision As %String, Directory As %String) As %Status
{
	Set Status = ..MoveProductions(Directory)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Checks all export files in a directory, and moves any file containing
/// a production to a subdirectory "Productions".
Method MoveProductions(Directory As %String) As %Status
{
	Set rs = ##class(%ResultSet).%New("%File:FileSet")
	Set Status = rs.Execute(Directory, "*.xml")
	If 'Status Quit $$$BuildErr("Error executing fileset query:", Status)
	
	While rs.Next() {
		Set FileName = rs.Get("Name")
		
		Kill Loaded
		Set Status = $System.OBJ.Load(FileName, "-d", , .Loaded, 1)
		If 'Status Return $$$BuildErr("Error loading export file {}:", Status, FileName)
		
		Set Name =""
		For  {
			Set Name = $Order(Loaded(Name))
			If Name = "" Quit
			
			If $Piece(Name, ".", *) '= "cls" Continue
			Set ClassName = $Piece(Name, ".", 1, *-1)
			
			;If we can't find this class or it's not compiled, we can't check if this is a production
			If '##class(%Dictionary.CompiledClass).%ExistsId(ClassName) {
				 Do ..Write("Warning: can't find compiled class "_ClassName)
				 Continue
			}
			If '$ZObjClassMethod(ClassName, "%IsA", "Ens.Production") Continue
			
			;A production. Make sure production directory present:
			Set Status = ..EnsureProductionDir(Directory)
			If 'Status Return Status
			
			;Move the file containing the production class
			Set NewName = ##class(Strix.Lib.File).AppendPath(Directory, "Productions", rs.Get("ItemName"))
			Set rc = ##class(%File).Rename(FileName, NewName, .ec)
			If 'rc Return $$$BuildErr("Error {} moving file {} to {}", , ec, FileName, NewName)
		}
	}
	
	Quit $$$OK
}

ClassMethod EnsureProductionDir(ReleaseDirectory As %String) As %Status
{
	Set ProdDir = ##class(%File).SubDirectoryName(ReleaseDirectory, "Productions")
	If ##class(%File).DirectoryExists(ProdDir) Quit $$$OK
	
	Set rc = ##class(%File).CreateDirectory(ProdDir, .ec)
	If 'rc Quit $$$BuildErr("Error {} creating directory {}", , ec, ProdDir)
	
	Quit $$$OK
}

}

