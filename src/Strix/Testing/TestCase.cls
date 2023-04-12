Include Strix

/// Superclass for tests to be run by Strix.Test.Runner.
Class Strix.Testing.TestCase Extends %RegisteredObject
{

Parameter ManualOnly As BOOLEAN = 0;

/// The test runner
Property Runner As Strix.Testing.Runner;

// =====

/// Callback: code to run before any test in this class is executed.
Method Setup() As %Status
{
	Quit $$$OK
}

/// Callback: code to run before a single test method is run. The name
/// of the method is passed in.
Method OnBeforeTest(Name As %String) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Callback: code to run after a single test method has been run. The
/// name of the method is passed in.
Method OnAfterTest(Name As %String) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Callback: code to run after all tests in this class have been executed.
/// Gets passed in a comma-separated list of methods with assertion
/// failures or errors.
Method TearDown(FailedTests As %String) As %Status
{
	Quit $$$OK
}

// =====

Method Assert(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = ''Result
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

/// Same as ..Assert
Method AssertTrue(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = ''Result
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertFalse(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = 'Result
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Expected = Result
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, Expected, Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertNotEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Expected '= Result
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, Expected, Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertNotEmpty(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Result '= ""
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

/// Asserts that string InValue contains string Expected.
Method AssertContains(Container, Value, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Container [ Value
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, Value, Container, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Value, Container, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertListEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = $ListSame(Expected, Result)
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, Expected, Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertListNotEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = '$ListSame(Expected, Result)
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, Expected, Result, Description)
	
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method AssertStatusOk(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Status = $$$OK
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, $$$OK, $$$OK, Description)
	
	Set StatusText = $System.Status.GetErrorText(Status)
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, $$$OK, StatusText, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertStatusEqual(Status1 As %Status, Status2 As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Ok = Status1 = Status2
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , , Description)
	
	Set Text1 = $System.Status.GetErrorText(Status1)
	Set Text2 = $System.Status.GetErrorText(Status2)
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, Text1, Text2, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertErrorStatus(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set Codes = $System.Status.GetErrorCodes(Status)
	Set Ok =  (Status '= "") && (Codes '= "") && (Codes '= $$$InvalidStatusCodeStruct)
	If '$IsObject(..Runner) Quit Ok
	
	Set Result = $System.Status.GetErrorText(Status)
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, , Result, Description)
	
	Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unknown]")
	Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Got, Description)
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

Method AssertStatusParameter(Status As %Status, ParmNr As %Integer, ParmValue As %String, Description As %String = "", Parms... As %String) As %Boolean
{
	Set sc = $System.Status.DecomposeStatus(Status, .Errors)
	Set Got = $Get(Errors(1, "param", ParmNr))
	
	Set Ok = sc && (Got = ParmValue)
	If '$IsObject(..Runner) Quit Ok
	
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	If Ok Quit ..Runner.RecordAssertionOk($$$CurrentMethod, ParmValue, Got, Description)
	
	If 'sc {
		; Invalid status, determine what the problem is
		Set Codes = $System.Status.GetErrorCodes(sc)
		Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unparseable status]")
		Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, , Got, Description)
		
	} Else {
		; Status ok, unexpected value for parameter
		Set Info = ..Runner.RecordAssertionFailed($$$CurrentMethod, ParmValue, Got, Description)
	}
	
	If ..Runner.Debug Do Info.ReportToTerminal() Break
	
	Quit 0
}

// ==

Method Log(Message As %String, Parms... As %String)
{
	Do ..Runner.RecordLog(Message, Parms...)
}

// ==

Method Skipped(Reason As %String) As %Boolean
{
	If '$IsObject(..Runner) Quit 0
	Do ..Runner.RecordTestSkipped(Reason)
	Quit 0
}

}

