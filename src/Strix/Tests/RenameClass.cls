/// Test code for Strix.Generator.Utilities:RenameClass()
/// Do ##class(Strix.Testing.Runner).Run("Strix.Tests.RenameClass")
Class Strix.Tests.RenameClass Extends Strix.Testing.TestCase
{

/// Base package for created test classes
Parameter TestPackage = "TestRenameClass";

// =====

/// Test basic rename
Method TestSuccess()
{
	Set From = ..#TestPackage_".Input"
	If '..AssertStatusOk(..CreateTestClass(From), "Create test source class {}", From) Quit
	
	Set To = ..#TestPackage_".Renamed"
	Set sc = ##class(Strix.Generator.Utilities).RenameClass(From, To)
	If '..AssertStatusOk(sc, "Renaming '{}' to '{}' works", From, To) Quit
	
	Do ..Assert(##class(%Dictionary.ClassDefinition).%ExistsId(To),
	    "Class exists under new name '{}'", To)
	Do ..Assert(##class(%Dictionary.PropertyDefinition).%ExistsId(To_"||a"),
	    "Renamed class '{}' has expected property 'a'", To)
	Do ..Assert('##class(%Dictionary.ClassDefinition).%ExistsId(From),
	    "Class no longer exists under old name '{}'", From)
	
	; By default, the new class will not be compiled
	Do ..AssertFalse($System.OBJ.IsUpToDate(To), "Renamed class '{}' is not compiled")
	
	Quit
}

/// Test class is compiled if so requested
Method TestCompile()
{
	Set From = ..#TestPackage_".Input"
	If '..AssertStatusOk(..CreateTestClass(From), "Create test source class {}", From) Quit
	
	Set To = ..#TestPackage_".Renamed"
	Set sc = ##class(Strix.Generator.Utilities).RenameClass(From, To, , 1)
	If '..AssertStatusOk(sc, "Renaming '{}' to '{}' works", From, To) Quit
	
	Do ..AssertTrue($System.OBJ.IsUpToDate(To), "Renamed class '{}' is compiled")
	
	Quit
}

/// Test destination class is not overwritten
Method TestNoOverwrite()
{
	Set From = ..#TestPackage_".Input"
	If '..AssertStatusOk(..CreateTestClass(From), "Create test source class {}", From) Quit
	
	Set To = ..#TestPackage_".Renamed"
	If '..AssertStatusOk(..CreateTestClass(To), "Create test dest class {}", To) Quit
	
	Set sc = ##class(Strix.Generator.Utilities).RenameClass(From, To)
	If '..AssertErrorStatus(sc, "Renaming '{}' to '{}' fails if dest exists", From, To) Quit
	
	Quit
}

/// Test destination class is overwritten if so requested
Method TestOverwrite()
{
	Set From = ..#TestPackage_".Input"
	If '..AssertStatusOk(..CreateTestClass(From), "Create test source class {}", From) Quit
	
	Set To = ..#TestPackage_".Renamed"
	If '..AssertStatusOk(..CreateTestClass(To), "Create test dest class {}", To) Quit
	
	Set sc = ##class(Strix.Generator.Utilities).RenameClass(From, To, 1)
	If '..AssertStatusOk(sc, "Overwriting '{}', if so requested, works", From, To) Quit
	
	Quit
}

// =====

/// Create a basic test class with a given name
Method CreateTestClass(Name As %String, Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	Set sc = ##class(Strix.Testing.Support).CreateClass(Name, "%RegisteredObject", .ClassDef)
	If 'sc Quit sc
	Do ##class(Strix.Testing.Support).AddProperty(ClassDef, "a", "%String")
	
	Set sc = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'sc Quit sc
	
	Quit $$$OK
}

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	Set sc = $System.OBJ.DeletePackage(..#TestPackage, "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test package {}:", sc, ..#TestPackage)
	Quit $$$OK
}

/// Delete generated classes after each test
Method OnAfterTest(Name As %String) As %Status
{
	Set sc = $System.OBJ.DeletePackage(..#TestPackage, "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test package {}:", sc, ..#TestPackage)
	Quit $$$OK
}

/// Final cleanup, if necessary
Method TearDown(FailedTests As %String) As %Status
{
	Set sc = $System.OBJ.DeletePackage(..#TestPackage, "-d")
	If 'sc Quit $$$BuildStatus("Error deleting test package {}:", sc, ..#TestPackage)
	Quit $$$OK
}

}
