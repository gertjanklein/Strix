/// This class records information about a testing 'event': an
/// assertion passed/failed, an error in setup code, etc.
Class Strix.Testing.Info Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLNAME = "Result";

/// The type of info:
/// Pass: an assertion was correct
/// Fail: an assertion failed
/// Skip: assertion skipped (optionally with reason)
/// Error: an error occurred (trapped)
/// Log: a message
Property Type As %String(VALUELIST = ",Pass,Fail,Skip,Error,Log") [ Required ];

/// The test class this information is related to
Property ClassName As %String(MAXLEN = 220);

/// The test method this info is related to
Property MethodName As %String(MAXLEN = 180);

/// For background tests, the location where the actual assertion
/// was checked (in the form ClassName:MethodName)
Property BackgroundLocation As %String(MAXLEN = 401);

/// The type of test that was performed:
/// Assert[Not]Equal, AssertTrue, AssertFalse, AssertStatusOk, AssertStatusFail
Property AssertionType As %String;

/// Expected result of the test (if appropriate)
Property Expected As %String(MAXLEN = 4000, TRUNCATE = 1);

/// Actual result of the test (if appropriate)
Property Result As %String(MAXLEN = 4000, TRUNCATE = 1);

/// Description of the test or log line
Property Description As %String(MAXLEN = 1000);

/// The error status for type Error
Property Status As %Status;

// =====

/// Contructor for normal info
ClassMethod Get(Type As %String, ClassName As %String = "", MethodName As %String = "", AssertionType As %String = "", Expected As %String = "", Result As %String = "", Description As %String = "") As Info
{
	Set Me = ..%New()
	Set Me.Type = Type
	Set Me.ClassName = ClassName
	Set Me.MethodName = MethodName
	Set Me.AssertionType = AssertionType
	Set Me.Expected = Expected
	Set Me.Result = Result
	Set Me.Description = Description
	Quit Me
}

/// Constructor for error info
ClassMethod GetForError(ClassName As %String = "", MethodName As %String = "", Description As %String = "", Status As %Status = "") As Info
{
	Set Me = ..%New()
	Set Me.Type = "Error"
	Set Me.ClassName = ClassName
	Set Me.MethodName = MethodName
	Set Me.Description = Description
	Set Me.Status = Status
	Quit Me
}

Method ReportToTerminal()
{
	If $X Write !
	
	If ..Type = "Fail" {
		Write ..AssertionType_" failed: "_..Description,!
		
		If $ListFind($ListFromString("AssertEqual,AssertNotEqual,AssertStatusParameter"), ..AssertionType) {
			Set Expected = ..Expected
			Set Result = ..Result
			Write "Expected: ",Expected,!
			Write "Result:   ",Result,!
			
		} ElseIf $ListFind($ListFromString("AssertListEqual,AssertListNotEqual"), ..AssertionType) {
			Set Expected = ..Expected
			Set Result = ..Result
			ZWrite Expected
			ZWrite Result
			
		} ElseIf $ListFind($ListFromString("AssertStatusOk,AssertErrorStatus,AssertTrue,AssertFalse"), ..AssertionType) {
			Write "Got: "_..Result,!
			
		} ElseIf ..AssertionType = "AssertStatusEqual" {
			Write "Status1: "_..Expected,!
			Write "Status2: "_..Result,!
			
		}
		
		Quit
	}
	
	If ..Type = "Skip" {
		Write "  Skipped"_$Select(..Description '= "": ": "_..Description, 1: " (no reason given)"),!
		Quit
	}
	
	If ..Type = "Error" {
		Write "Error: "_..Description,!
		If ..Status '= "", '..Status Write $System.Status.GetErrorText(..Status),!
		Quit
	}
	
	If ..Type = "Log" {
		Write "Message: "_..Description,!
		Quit
	}
	
	;Unrecognised, dump object
	Do $system.OBJ.Dump(##this)
	
	Quit
}

/// Simple JSON serialization
Method ToJSON() As %String
{
	Set JSON = {
	  "type": (..Type),
	  "classname": (..ClassName),
	  "methodname": (..MethodName),
	  "assertiontype": (..AssertionType),
	  "expected": (..Expected),
	  "result": (..Result),
	  "description": (..Description),
	  "status": (..Status)
	}
	Quit JSON.%ToJSON()
}

/// Simple JSON deserialization
ClassMethod FromJSON(JSON As %String) As Strix.Testing.Info
{
	Set Obj = {}.%FromJSON(JSON)
	Set Me = ..%New()
	Set Me.Type = Obj.type
	Set Me.ClassName = Obj.classname
	Set Me.MethodName = Obj.methodname
	Set Me.AssertionType = Obj.assertiontype
	Set Me.Expected = Obj.expected
	Set Me.Result = Obj.result
	Set Me.Description = Obj.description
	Set Me.Status = Obj.status
	Quit Me
}

// =====

Storage Default
{
<Data name="InfoState">
<Value name="1">
<Value>Type</Value>
</Value>
<Value name="2">
<Value>ClassName</Value>
</Value>
<Value name="3">
<Value>MethodName</Value>
</Value>
<Value name="4">
<Value>AssertionType</Value>
</Value>
<Value name="5">
<Value>Expected</Value>
</Value>
<Value name="6">
<Value>Result</Value>
</Value>
<Value name="7">
<Value>Description</Value>
</Value>
<Value name="8">
<Value>Status</Value>
</Value>
<Value name="9">
<Value>BackgroundLocation</Value>
</Value>
</Data>
<State>InfoState</State>
<StreamLocation>^Strix.Testing.InfoS</StreamLocation>
<Type>%Library.CacheSerialState</Type>
}

}

