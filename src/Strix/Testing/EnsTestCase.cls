Include (Ensemble, Strix)

/// Superclass for tests to be run in Ensemble components. Intended as
/// a mixin for BPs and BOs. Returns results in a gobal node based on
/// SessionId.
Class Strix.Testing.EnsTestCase Extends Ens.Host
{

/// The currently executing test method. We determine this by examining
/// the call stack one level up.
Property TestMethod As %String;

// =====

Method Assert(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Result Quit ..RecordAssertionOk($$$CurrentMethod, , Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, , Result, Description, Parms...)
}

/// Same as ..Assert
Method AssertTrue(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Result Quit ..RecordAssertionOk($$$CurrentMethod, , Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, , Result, Description, Parms...)
}

Method AssertFalse(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If 'Result Quit ..RecordAssertionOk($$$CurrentMethod, , Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, , Result, Description, Parms...)
}

// ==

Method AssertEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Expected = Result Quit ..RecordAssertionOk($$$CurrentMethod, Expected, Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description, Parms...)
}

Method AssertNotEqual(Result, Expected, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Expected '= Result Quit ..RecordAssertionOk($$$CurrentMethod, Expected, Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description, Parms...)
}

Method AssertNotEmpty(Result, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Result '= "" Quit ..RecordAssertionOk($$$CurrentMethod, , Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, , Result, Description, Parms...)
}

// ==

/// Asserts that string Container contains string Value.
Method AssertContains(Container, Value, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Container [ Value Quit ..RecordAssertionOk($$$CurrentMethod, Value, Container, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Value, Container, Description, Parms...)
}

// ==

/// Asserts that two %List values are equal. Uses $ListSame to determine.
Method AssertListEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If $ListSame(Expected, Result) Quit ..RecordAssertionOk($$$CurrentMethod, Expected, Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description, Parms...)
}

/// Asserts that two %List values are unequal. Uses $ListSame to determine.
Method AssertListNotEqual(Result As %List, Expected As %List, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If '$ListSame(Expected, Result) Quit ..RecordAssertionOk($$$CurrentMethod, Expected, Result, Description, Parms...)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Expected, Result, Description, Parms...)
}

// ==

/// Asserts that the %Status value is $$$OK
Method AssertStatusOk(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Status = $$$OK Quit ..RecordAssertionOk($$$CurrentMethod, $$$OK, $$$OK, Description, Parms...)
	Set StatusText = $System.Status.GetErrorText(Status, "en")
	Quit ..RecordAssertionFailed($$$CurrentMethod, $$$OK, StatusText, Description, Parms...)
}

Method AssertStatusEqual(Status1 As %Status, Status2 As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	If Status1 = Status2 Quit ..RecordAssertionOk($$$CurrentMethod, Status1, Status2, Description, Parms...)
	Set Text1 = $System.Status.GetErrorText(Status1)
	Set Text2 = $System.Status.GetErrorText(Status2)
	Quit ..RecordAssertionFailed($$$CurrentMethod, Text1, Text2, Description, Parms...)
}

/// Asserts the Status passed in is a proper error %Status
Method AssertErrorStatus(Status As %Status, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	Set Codes = $System.Status.GetErrorCodes(Status)
	If Status '= "", Codes '= "", Codes '= $$$InvalidStatusCodeStruct Quit ..RecordAssertionOk($$$CurrentMethod, , Status, Description, Parms...)
	Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unknown]")
	Quit ..RecordAssertionFailed($$$CurrentMethod, , Got, Description, Parms...)
}

/// Asserts that an error %Status has a given parameter number set
/// to a given value.
Method AssertStatusParameter(Status As %Status, ParmNr As %Integer, ParmValue As %String, Description As %String = "", Parms... As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	; First make sure status is valid
	Set sc = $System.Status.DecomposeStatus(Status, .Errors)
	If 'sc {
		Set Codes = $System.Status.GetErrorCodes(sc)
		Set Got = $Select(Status = $$$OK: "[ok status]", Status = "": "[empty status]", Codes = $$$InvalidStatusCodeStruct: "[invalid status]", 1: "[unparseable status]")
		Do ..RecordAssertionFailed($$$CurrentMethod, , Got, Description, Parms...)
	}
	
	Set Got = $Get(Errors(1, "param", ParmNr))
	If Got = ParmValue Quit ..RecordAssertionOk($$$CurrentMethod, ParmValue, Got, Description, Parms...)
	
	Quit ..RecordAssertionFailed($$$CurrentMethod, ParmValue, Got, Description, Parms...)
}

// ==

Method Skipped(Reason As %String) As %Boolean
{
	Set ..TestMethod = ..ParsePlace($Stack($Stack-1,"PLACE"))
	Do ..RecordTestSkipped(Reason)
	Quit 0
}

// =====

/// Records a successful assertion.
Method RecordAssertionOk(AssertionType As %String, Expected As %String = "", Result As %String = "", Description As %String = "", Parms... As %String) As %Boolean
{
	If ..%SessionId = "" $$$LOGWARNING("No session set in "_$ClassName()_"/"_..TestMethod_".") Quit 1
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	Set Node = ##class(Strix.Testing.Runner).NextBgTestNode(..%SessionId)
	Set @Node@("w") = $ClassName()_":"_..TestMethod
	Set Info = ##class(Strix.Testing.Result).Get("Pass", $ClassName(), ..TestMethod, AssertionType, Expected, Result, Description)
	Set @Node = Info.ToJSON()
	
	Quit 1
}

/// Records a failed assertion.
Method RecordAssertionFailed(AssertionType As %String, Expected As %String = "", Result As %String = "", Description As %String = "", Parms... As %String) As %Boolean
{
	If ..%SessionId = "" $$$LOGWARNING("No session set in "_$ClassName()_"/"_..TestMethod_".") Quit 0
	If $Get(Parms) Set Description = $$$BuildStr(Description, Parms...)
	
	Set Node = ##class(Strix.Testing.Runner).NextBgTestNode(..%SessionId)
	Set @Node@("w") = $ClassName()_":"_..TestMethod
	Set Info = ##class(Strix.Testing.Result).Get("Fail", $ClassName(), ..TestMethod, AssertionType, Expected, Result, Description)
	Set @Node = Info.ToJSON()
	
	Quit 0
}

/// Records a test skip.
Method RecordTestSkipped(Reason As %String = "")
{
	If ..%SessionId = "" $$$LOGWARNING("No session set in "_$ClassName()_"/"_..TestMethod_".") Quit
	Set Node = ##class(Strix.Testing.Runner).NextBgTestNode(..%SessionId)
	Set @Node@("w") = $ClassName()_":"_..TestMethod
	Set Info = ##class(Strix.Testing.Result).Get("Skip", $ClassName(), ..TestMethod, , , , Reason)
	Set @Node = Info.ToJSON()
	Quit
}

/// Records an error (e.g. trapped error, error status, etc.).
Method RecordError(Description As %String = "", Status As %Status = "")
{
	If ..%SessionId = "" $$$LOGWARNING("No session set in "_$ClassName()_"/"_..TestMethod_".") Quit
	Set Node = ##class(Strix.Testing.Runner).NextBgTestNode(..%SessionId)
	Set @Node@("w") = $ClassName()_":"_..TestMethod
	Set Info = ##class(Strix.Testing.Result).GetForError($ClassName(), ..TestMethod, Description, Status)
	Set @Node = Info.ToJSON()
	Quit
}

/// Extracts the method name from a PLACE type $Stack string
ClassMethod ParsePlace(Place As %String) As %String
{
	Set Place = $Piece($Piece(Place, "^"), "+")
	If $Extract(Place) = "z" Set Place = $Extract(Place, 2, *)
	Quit Place
}

}
