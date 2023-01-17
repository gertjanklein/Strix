/// Superclass for testcases for testing Ensemble components.
/// Contains some helper setup code:
/// - Automatically start and stop the test production, if
///   specified (in parameter ProductionName)
/// - Creates a test service, ready to make calls from, for
///   each test method
/// - Automatically collects background tests (i.e., assertions
///   that were run in different Ensemble components)
/// - If call information is recorded by Strix.Testing.Ens.BusinessOperation,
///   helper code can be used to get them into property ..Calls
/// - An AssertInCalls assertion makes sure a specific Ensemble
///   request has been made
Class Strix.Testing.EnsTestHelper Extends Strix.Testing.TestCase
{

/// Name of the Ensemble production to automatically start in
/// the Setup() method of this class
Parameter ProductionName;

// =====

/// Whether to check for requests/responses with error status
/// automatically after each test. This can be turned off in
/// tests for error handling, but should normally be on.
Property CheckEnsembleErrors As %Boolean [ InitialExpression = 1 ];

/// The testing service to use to send requests with. Will be initialized
/// before each test run.
Property Service As EnsLib.Testing.Service;

/// The session id for the request to send. Used to communicate between
/// test methods and the Ensemble test support mixin.
Property SessionId As %String;

/// The location of the currently running test;
/// ClassName:MethodName.
Property Location As %String;

/// Calls to business operations that have been recorded
/// classname -> id[,id[,...]]
Property Calls As array Of %String;

// =====

/// Initialise a test Ensemble service, and determine SessionId
Method OnBeforeTest(Name As %String) As %Status
{
	; Determine test location
	Set ..Location = ..Runner.CurrentTestClass_":"_..Runner.CurrentTestMethod
	
	; Create EnsLib.Testing.Service instance
	Set sc = ##class(Strix.Testing.EnsSupport).GetTestService(.Service, .SessionId, ..Location)
	If '..AssertStatusOk(sc, "Retrieving test service") Quit sc
	
	Set ..Service = Service
	Set ..SessionId = SessionId
	
	Quit $$$OK
}

/// Collect test results
Method OnAfterTest(Name As %String) As %Status
{
	; Collect background tests, and clear test data
	Do ..Runner.CollectBgTests(..SessionId, 1)
	
	; No check for error status: we're done
	If '..CheckEnsembleErrors Quit $$$OK
	
	; Check whether any Ensemble message in the session has an error status
	Set err = ##class(Strix.Testing.EnsSupport).CheckErrorStatus(..SessionId, .MsgId, .MsgDesc, .MsgStatus) 
	If 'err Quit $$$OK
	
	; Report the error via an assertion
	Do ..AssertStatusOk(MsgStatus, "Message {} in session {} ({}) has error status", MsgId, ..SessionId, MsgDesc)
	
	Quit $$$OK
}

// =====

/// Collects calls recorded while executing a test in
/// property ..Calls.
/// ClearIn specifies whether to delete the recorded data
///   after collecting
/// ClearOut specifies whether to clear ..Calls before
///   collecting
Method GetCalls(ClearIn As %Boolean = 1, ClearOut As %Boolean = 1)
{
	If ClearOut Do ..Calls.Clear()
	
	Set Calls = ..Runner.GetTestData(..SessionId, "Calls")
	
	For i = 1:1:$ListLength(Calls) {
		Set CallItem = $List(Calls, i)
		Set ClassName = $List(CallItem, 1), Id = $List(CallItem, 2)
		If ..Calls.IsDefined(ClassName) {
			Set Id = ..Calls.GetAt(ClassName)_","_Id
		}
		Do ..Calls.SetAt(Id, ClassName)
	}
	
	If ClearIn Do ..Runner.SetTestData(..SessionId, "Calls", "")
	
	Quit
}

/// Helper that checks whether calls with the specified request
/// classname are recorded. Optionally checks for a specific
/// number of calls as well. Count may be 0 to check no calls
/// were performed.
Method AssertInCalls(ClassName As %String, Count As %Integer = "") As %Boolean
{
	If Count = 0 Quit ..Assert('..Calls.IsDefined(ClassName), "Expected no {} call", ClassName)
	If '..Assert(..Calls.IsDefined(ClassName), "Expected a {} call", ClassName) Quit 0
	If Count = "" Quit 1
	Set Present = $Length(..Calls.GetAt(ClassName), ",")
	If '..AssertEqual(Present, Count, "Expected {} calls with {}", Count, ClassName) Quit 0
	Quit 1
}

// =====

/// Start the production for the tests
Method Setup() As %Status
{
	If ..#ProductionName = "" Quit $$$OK
	Set sc = ##class(Strix.Testing.EnsSupport).EnsureProduction(..#ProductionName)
	If 'sc Quit sc
	Quit $$$OK
}

/// Stop the production started for the tests
Method TearDown(FailedTests As %String) As %Status
{
	If ..#ProductionName = "" Quit $$$OK
	Set sc = ##class(Strix.Testing.EnsSupport).StopProduction()
	If 'sc Quit $$$BuildStatus("Error stopping running production:", sc)
	Quit $$$OK
}

}

