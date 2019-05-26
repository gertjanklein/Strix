Include Strix

/// Superclass for tests to be run by Strix.Test.Runner.
Class Strix.Testing.TestCase Extends %RegisteredObject
{

/// The test runner
Property Runner As Strix.Testing.Runner;

// =====

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	Quit $$$OK
}

/// Code to run after a single test method has been run. The name
/// of the method is passed in.
Method OnAfterTest(Name As %String) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Code to run after all tests in this class have been executed.
/// Gets passed in a comma-separated list of methods with assertion
/// failures or errors.
Method TearDown(FailedTests As %String) As %Status
{
	Quit $$$OK
}

// =====

Method Assert(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	If Result {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

/// Alias for ..Assert
Method AssertTrue(Result, Description As %String = "", Parms... As %String) As %Boolean [ CodeMode = expression ]
{
..Assert(.Result, .Description, Parms...)
}

Method AssertFalse(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	If 'Result {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	If Expected = Result {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertNotEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	If Expected '= Result {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertNotEmpty(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	If Result '= "" {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

/// Asserts that string InValue contains string Expected.
Method AssertContains(Container, Value, Description As %String = "", Parms... As %String) As %Boolean
{
	If Container [ Value {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Value, Container, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertListEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	If $ListSame(Expected, Result) {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertListNotEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	If '$ListSame(Expected, Result) {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertStatusOk(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	If Status = $$$OK {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set StatusText = $System.Status.GetErrorText(Status)
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, $$$OK, StatusText, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertStatusEqual(Status1 As %Status, Status2 As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	If Status1 = Status2 {
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	
	Set Text1 = $System.Status.GetErrorText(Status1)
	Set Text2 = $System.Status.GetErrorText(Status2)
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Text1, Text2, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertErrorStatus(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Codes = $System.Status.GetErrorCodes(Status)
	If Status '= "", Codes '= "", Codes '= $$$InvalidStatusCodeStruct {
		;A valid error %Status
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unknown]")
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Got, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertStatusParameter(Status As %Status, ParmNr As %Integer, ParmValue As %String, Description As %String = "", Parms... As %String) As %Boolean
{
	Set sc = $System.Status.DecomposeStatus(Status, .Errors)
	If 'sc {
		$$$ToTerm("E")
		If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
		Set Codes = $System.Status.GetErrorCodes(sc)
		If '$IsObject(..Runner) Quit 0
		Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unparseable status]")
		Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Got, Description)
		If ..Runner.Debug Do Info.ReportToTerminal() Break
		Quit 0
	}
	
	If $Get(Errors(1, "param", ParmNr)) = ParmValue {
		; Parameter value as expected
		$$$ToTerm(".")
		If $IsObject(..Runner) Do ..Runner.RecordAssertionOk()
		Quit 1
	}
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	$$$ToTerm("E")
	If '$IsObject(..Runner) Quit 0
	Set Got = $Get(Errors(1, "param", ParmNr))
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, ParmValue, Got, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method Skipped(Reason As %String) As %Boolean
{
	$$$ToTerm("S")
	If '$IsObject(..Runner) Quit 0
	Do ..Runner.RecordTestSkipped(Reason)
	Quit 0
}

}

