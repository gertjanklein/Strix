/// Removes Ensemble Production classes from the export.
Class Strix.SCM.Processor.RemoveEnsProd Extends Strix.SCM.Processor.Base
{

/// This processor works on a release.
Parameter HandlerType = "Release";

// =====

Method Run(Revision As %String, Directory As %String) As %Status
{
	Set Status = ..RemoveProductions(Directory)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Checks all export files in a directory, and removes any file containing
/// an Ensemble production.
Method RemoveProductions(Directory As %String) As %Status
{
	Set rs = ##class(%ResultSet).%New("%File:FileSet")
	Set Status = rs.Execute(Directory, "*.xml")
	If 'Status Quit $$$BuildErr("Error executing fileset query:", Status)
	
	While rs.Next() {
		Set FileName = rs.Get("Name"), ItemName = rs.Get("ItemName")
		
		Kill Loaded
		Set Status = $System.OBJ.Load(FileName, "-d", , .Loaded, 1)
		If 'Status Return $$$BuildErr("Error loading export file {}:", Status, FileName)
		
		Set Name =""
		For  {
			Set Name = $Order(Loaded(Name))
			If Name = "" Quit
			
			If $Piece(Name, ".", *) '= "cls" Continue
			Set ClassName = $Piece(Name, ".", 1, *-1)
			
			If ##class(%Dictionary.CompiledClass).%ExistsId(ClassName) {
				If '$ZObjClassMethod(ClassName, "%IsA", "Ens.Production") Continue
				
			} Else {
				 Do ..Write("Warning: class "_ClassName_" not compiled.")
				 Set MROList = ##class(Strix.Generator.Utilities).MRO(ClassName, 0)
				 If '$ListFind(MROList, "Ens.Production") Continue
				 
			}
			
			;A production. Remove this file:
			Do ..Write("Removing "_ItemName_" from release because it contains an Ensemble production.")
			Set rc = ##class(%File).Delete(FileName, .ec)
			If 'rc Return $$$BuildErr("Error {} removing file {}.", , ec, FileName)
		}
	}
	
	Quit $$$OK
}

}
