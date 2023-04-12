/// Do ##class(Strix.Testing.Runner).Run("Strix.Tests.Export")
Class Strix.Tests.Export Extends Strix.Testing.TestCase
{

/// The name of the export file to use
Property Exportfile As %String;

/// Tests exporting an item without any dependencies
Method TestNoDeps()
{
	Set Item = "Strix.Std.EAN.cls"
	
	Set ok = ##class(Strix.Lib.Export).Export(Item, ..Exportfile)
	If '..Assert(ok, "Export should succeed") Quit
	
	Set sc = ..ListAndDelete(.Items)
	If '..AssertStatusOk(sc, "Should be able to list items in export") Quit
	
	; Check if item in export
	Do ..Assert($Data(Items(Item)), "Item to export should be present")
	; ...and no others
	Do ..AssertEqual(Items, 1, "Only one item should be in export")
	
	Quit
}

/// Test exporting a package without dependencies
Method TestPackage()
{
	Set Package = "Strix.Std.pkg"
	
	Set ok = ##class(Strix.Lib.Export).Export(Package, ..Exportfile)
	If '..Assert(ok, "Export should succeed") Quit
	
	Set sc = ..ListAndDelete(.Items)
	If '..AssertStatusOk(sc, "Should be able to list items in export") Quit
	
	; Check if expected items in export
	For Item = "Strix.Std.EAN", "Strix.Std.IBAN", "Strix.Std.VATNumber" {
		Do ..Assert($Data(Items(Item_".cls")), "Item {} should be present", Item)
	}
	
	; ...and no others
	Do ..AssertEqual(Items, 3, "Only 3 items should be in export")
	
	Quit
}

/// Test excluding classes from the export
Method TestExclude()
{
	Set Package = "Strix.Std.pkg"
	Set Exclude = "Strix.Std.EAN.cls,Strix.Std.IBAN.cls"
	
	Set ok = ##class(Strix.Lib.Export).Export(Package, ..Exportfile, Exclude)
	If '..Assert(ok, "Export should succeed") Quit
	
	Set sc = ..ListAndDelete(.Items)
	If '..AssertStatusOk(sc, "Should be able to list items in export") Quit
	
	; Check if expected item in export
	Do ..Assert($Data(Items("Strix.Std.VATNumber.cls")), "VATNumber.cls should still be present")
	
	; ...and no others
	Do ..AssertEqual(Items, 1, "Only one item should be in export")
	
	Quit
}

/// Tests excluding a package from the export
Method TestExcludePkg()
{
	Set Package = "Strix.Tests.Tree.pkg"
	Set Exclude = "Strix.Tests.Tree.pkg1.pkg"
	
	Set ok = ##class(Strix.Lib.Export).Export(Package, ..Exportfile, Exclude)
	If '..Assert(ok, "Export should succeed") Quit
	
	Set sc = ..ListAndDelete(.Items)
	If '..AssertStatusOk(sc, "Should be able to list items in export") Quit
	
	; Check if expected items in export
	For Item = "Strix.Tests.Tree.a", "Strix.Tests.Tree.pkg2.b", "Strix.Tests.Tree.pkg2.c" {
		Do ..Assert($Data(Items(Item_".cls")), "Item {} should be present", Item)
	}
	
	; ...and no others
	Do ..AssertEqual(Items, 3, "Only 3 items should be in export")
	
	Quit
}

// =====

Method ListAndDelete(Output Items As %String) As %Status
{
	Kill Items
	Set Items = 0
	
	; List items in export file
	Set sc = $System.OBJ.Load(..Exportfile, "-d", , .List, 1)
	If 'sc Quit sc
	
	; Copy names while counting them
	Set Name = ""
	For  {
		Set Name = $Order(List(Name))
		If Name = "" Quit
		Set Items = Items + 1
		Set Items(Name) = ""
	}
	
	; ...and delete the file
	Do ##class(%File).Delete(..Exportfile)
	
	Quit $$$OK
}

Method Setup() As %Status
{
	Set ..Exportfile = ##class(%File).TempFilename(".xml")
	
	; Create tree of test classes
	Set TstPkg = "Strix.Tests.Tree"
	For Class = "a", "pkg1.b", "pkg1.c", "pkg2.b", "pkg2.c" {
		Set Name = TstPkg_"."_Class
		Set sc = ##class(Strix.Testing.Support).CreateClass(Name, , .Dic)
		If 'sc Return $$$BuildStatus("Error creating test class {}:", sc, Name)
		Set sc = Dic.%Save()
		If 'sc Return $$$BuildStatus("Error Saving test class {}:", sc, Name)
	}
	
	Quit $$$OK
}

Method TearDown(FailedTests As %String) As %Status
{
	Do ##class(%File).Delete(..Exportfile)
	Set sc = $System.OBJ.DeletePackage("Strix.Tests.Tree", "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test class tree:", sc)
	Quit $$$OK
}

}

