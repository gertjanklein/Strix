Include Strix

Class Strix.Testing.Runner Extends %RegisteredObject
{

// =====

/// Debug flag; when set and an assertion fails, a Break is executed.
Property Debug As %Boolean [ InitialExpression = 0 ];

// =====

/// Date/time the test run started
Property TestRunStart As %TimeStamp [ InitialExpression = {$ZDateTime($ZUtil(188), 3, 1, 3)} ];

/// Date/time the test run finished
Property TestRunDone As %TimeStamp;

/// Information on test failures, trapped errors, etc.
Property Results As list Of Strix.Testing.Info(STORAGEDEFAULT = "array");

/// Number of testcases (classes) seen in this test run
Property TestCases As %Integer [ InitialExpression = 0 ];

/// Number of tests (methods) seen in this test run
Property Tests As %Integer [ InitialExpression = 0 ];

/// Total number of asserts in this test run
Property Asserts As %Integer [ InitialExpression = 0 ];

/// Number of failed asserts in this test run
Property Failed As %Integer [ InitialExpression = 0 ];

/// Number of skipped tests in this test run
Property Skipped As %Integer [ InitialExpression = 0 ];

/// Number errors trapped/returned in this test run
Property Errors As %Integer [ InitialExpression = 0 ];

// =====

/// Bookkeeping: current testcase
Property CurrentTestClass As %String [ Internal, Transient ];

/// Bookkeeping: current testcase method
Property CurrentTestMethod As %String [ Internal, Transient ];

// =====

/// Runs all tests in the specified package.
ClassMethod Run(Package As %String, Debug As %Boolean = 0, Output Runner As Strix.Testing.Runner) As %Status
{
	Set Runner = ..%New()
	Set Runner.Debug = Debug
	
	Set (ClassName, MethodName) = ""
	If Package [ ":" {
		Set ClassName = $Piece(Package, ":", 1)
		Set MethodName = $Piece(Package, ":", 2)
		
	} ElseIf ##class(%Dictionary.ClassDefinition).%ExistsId(Package) {
		Set ClassName = Package
		
	}
	
	If ClassName '= "" {
		Set sc = Runner.RunClass(ClassName, MethodName)
		If 'sc Do Runner.RecordError("Error running testcase '"_ClassName_"'", sc)
		Set Runner.TestRunDone = $ZDateTime($ZUtil(188), 3, 1, 3)
		Do Runner.ReportToTerminal()
		
	} Else {
		Set sc = Runner.RunPackage(Package)
		If 'sc Quit sc
		
	}
	
	Quit $$$OK
}

Method RunPackage(Package As %String) As %Status
{
	Set sc = $System.OBJ.GetPackageList(.Classes, Package, "/includesubpackages")
	If 'sc Quit $$$BuildErr("Error creating list of classes in '"_Package_"'", sc)
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Classes(ClassName))
		If ClassName = "" Quit
		
		;Skip uncompiled classes
		If '##class(%Dictionary.CompiledClass).%ExistsId(ClassName) Continue
		
		;Skip classes not inheriting from the test superclass
		If '$ZObjClassMethod(ClassName, "%IsA", "Strix.Testing.TestCase") Continue
		
		Set sc = ..RunClass(ClassName)
		If 'sc Do ..RecordError("Error running testcase '"_ClassName_"'", sc)
	}
	
	Set ..TestRunDone = $ZDateTime($ZUtil(188), 3, 1, 3)
	
	Do ..ReportToTerminal()
	
	
	Quit $$$OK
}

/// Runs test methods in the specified subclass of Strix.Testing.TestCase
Method RunClass(ClassName As %String, TestToRun As %String = "") As %Status
{
	Set ..CurrentTestClass = ClassName, ..CurrentTestMethod = ""
	Set ..TestCases = ..TestCases + 1
	
	#dim TestObject As Strix.Testing.TestCase
	Set TestObject = $ZObjClassMethod(ClassName, "%New")
	If '$IsObject(TestObject) Quit $$$BuildErr("Error creating instance of '"_ClassName_"'", %objlasterror)
	Set TestObject.Runner = ##this
	
	Set sc = ..GetTestMethods(ClassName, .MethodNames)
	If 'sc Quit $$$BuildErr("Error determining test methods in class '"_ClassName_"'", sc)
	
	;Run setup
	Set ..CurrentTestMethod = "Setup"
	Set sc = TestObject.Setup()
	If 'sc Quit $$$BuildErr("Error running Setup", sc)
	
	Set FailedMethods = ""
	#dim MethodNames As %ListOfDataTypes
	For i = 1:1:MethodNames.Count() {
		Set MethodName = MethodNames.GetAt(i)
		If TestToRun '= "", TestToRun '= MethodName Continue
		Do ..RunMethod(TestObject, MethodName, .Failures, .Errors)
		If Failures + Errors Set FailedMethods = FailedMethods_$lb(MethodName)
	}
	
	;Run teardown
	Set ..CurrentTestMethod = "TearDown"
	Set sc = TestObject.TearDown($lts(FailedMethods))
	If 'sc Quit $$$BuildErr("Error running TearDown", sc)
	
	Quit $$$OK
}

/// Runs a single test method on the test object. Traps and returns any error.
Method RunMethod(TestObject As Strix.Testing.TestCase, MethodName As %String, Output Failed As %Integer, Output Errors As %Integer)
{
	Set $ZTrap = "Error"
	
	Set ..CurrentTestMethod = MethodName
	If ..CurrentTestClass = "" Set ..CurrentTestClass = TestObject.%ClassName(1)
	Set ..Tests = ..Tests + 1
	
	Set CurrentFailed = ..Failed, CurrentErrors = ..Errors
	
	; Run code in OnBeforeTest, if present
	If ##class(Strix.Generator.Utilities).HasConcreteMethod(..CurrentTestClass, "OnBeforeTest") {
		Set sc = $ZObjMethod(TestObject, "OnBeforeTest", MethodName)
		If 'sc Do ..RecordError("OnBeforeTest in "_..CurrentTestClass_" returned an error.", sc)
	}
	
	; Run the actual test
	Do $ZObjMethod(TestObject, MethodName)
	
	If ##class(Strix.Generator.Utilities).HasConcreteMethod(..CurrentTestClass, "OnAfterTest") {
		Set sc = $ZObjMethod(TestObject, "OnAfterTest", MethodName)
		If 'sc Do ..RecordError("OnAfterTest in "_..CurrentTestClass_" returned an error.", sc)
	}
	
	Set Failed = ..Failed - CurrentFailed
	Set Errors = ..Errors - CurrentErrors
	
	Quit
	
	
Error
	Set $ZTrap = ""
	
	Do ..RecordError("Error running test method '"_MethodName_"': "_$ZError)
	Set Failed = ..Failed - CurrentFailed
	Set Errors = ..Errors - CurrentErrors
	
	Quit
}

// ===== Support for background tests (EnsTestCase)

/// Returns the global node to use for background test communication.
/// A unique node number must be passed in; in Ensemble testcases
/// this should be the session id, as it's available everywhere.
ClassMethod GetBgTestNode(NodeId As %String, Clear As %Boolean = 0) As %String
{
	Set Node = $Name(^Strix.Testing.BgTestCase(NodeId, "tests"))
	If Clear Kill @Node
	Quit Node
}

/// Increments the test node counter, and returns a reference to the 
/// new test node subscript.
ClassMethod NextBgTestNode(NodeId As %String) As %String
{
	Set Idx = $Increment(^Strix.Testing.BgTestCase(NodeId, "tests"))
	Quit $Name(^Strix.Testing.BgTestCase(NodeId, "tests", Idx))
}

/// Stores the source of the tests, i.e., the test class+method where
/// the Ensemble call was made. Source may be specified as one string,
/// or as separate classname and methodname.
ClassMethod SetSource(NodeId As %String, Source As %String, Method As %String = "")
{
	If Method '= "" Set Source = Source_":"_Method
	Set ^Strix.Testing.BgTestCase(NodeId, "src") = Source
	Quit
}

/// Retrieves the source of the tests, i.e., the test class+method where
/// the Ensemble call was made.
ClassMethod GetSource(NodeId As %String) As %String
{
	Quit $Get(^Strix.Testing.BgTestCase(NodeId, "src"))
}

/// Places named test data in the test node. Can be used to communicate
/// information to a background test.
ClassMethod SetTestData(NodeId As %String, Name As %String, Value As %String)
{
	Set ^Strix.Testing.BgTestCase(NodeId, "data", Name) = Value
	Quit
}

/// Retrieves anamed test data from the test node. If not present, an
/// empty string is returned.
ClassMethod GetTestData(NodeId As %String, Name As %String, Output Found As %Boolean) As %String
{
	Set Found = $Data(^Strix.Testing.BgTestCase(NodeId, "data", Name)) # 10
	If Found Quit ^Strix.Testing.BgTestCase(NodeId, "data", Name)
	Quit ""
}

/// Clears all test data in the test node.
ClassMethod ClearTestData(NodeId As %String)
{
	Kill ^Strix.Testing.BgTestCase(NodeId, "data")
}

/// Collects test information for tests that have run in the background.
/// Pass in the node where the tests were collected; clears the node
/// unless told not to. Note that this clears the test data as well.
Method CollectBgTests(NodeId As %String, Clear As %Boolean = 1)
{
	Set Node = ..GetBgTestNode(NodeId)
	Set Count = $Get(@Node)
	Set ..Asserts = ..Asserts + Count
	
	For i = 1:1:Count {
		; Get JSON-serialized testresult data and convert to Info object
		Set Data = @Node@(i)
		#dim Info As Strix.Testing.Info
		Set Info = ##class(Strix.Testing.Info).FromJSON(Data)
		
		; Update test location information
		Set Info.BackgroundLocation = Info.ClassName_":"_Info.MethodName
		Set Info.ClassName = ..CurrentTestClass
		Set Info.MethodName = ..CurrentTestMethod
		
		; Insert in results
		Do ..Results.Insert(Info)
		
		; Count type 
		If Info.Type = "Pass" {
			Do ..ToTerm(".")
		} ElseIf Info.Type = "Fail" {
			Set ..Failed = ..Failed + 1
			Do ..ToTerm("F")
		} ElseIf Info.Type = "Skip" {
			Set ..Skipped = ..Skipped + 1
			Do ..ToTerm("S")
		} ElseIf Info.Type = "Error" {
			Set ..Errors = ..Errors + 1
			Do ..ToTerm("E")
		} Else {
			; We don't really support logging yet
			Do ..ToTerm("L")
		}
	}
	
	; Remove all data if so requested
	If Clear Kill ^Strix.Testing.BgTestCase(NodeId)
	
	Quit
}

// =====

/// Returns a list of method names in the specified class starting with Test.
ClassMethod GetTestMethods(ClassName As %String, Methods As %ListOfDataTypes) As %Status
{
	Set Methods = ##class(%ListOfDataTypes).%New()
	
	&sql(DECLARE C CURSOR FOR
	      SELECT Name INTO :Name
	        FROM %Dictionary.MethodDefinition
	       WHERE parent->Name = :ClassName
	         AND Name LIKE 'Test%')
	&sql(OPEN C)
	
	For  {
		&sql(FETCH C)
		If SQLCODE Quit
		
		Do Methods.Insert(Name)
	}
	&sql(CLOSE C)
	
	Quit $$$OK
}

// ===== TestCase callbacks

/// Records a successful assertion
Method RecordAssertionOk(AssertionType As %String, Expected As %String = "", Result As %String = "", Description As %String = "") As %Boolean
{
	Set ..Asserts = ..Asserts + 1
	Do ..ToTerm(".")
	Set Info = ##class(Strix.Testing.Info).Get("Pass", ..CurrentTestClass, ..CurrentTestMethod, AssertionType, Expected, Result, Description)
	Do ..Results.Insert(Info)
	Quit 1
}

/// Records a failed assertion.
Method RecordAssertionFailed(AssertionType As %String, Expected As %String = "", Result As %String = "", Description As %String = "") As Strix.Testing.Info
{
	Set ..Failed = ..Failed + 1
	Do ..ToTerm("F")
	Set Info = ##class(Strix.Testing.Info).Get("Fail", ..CurrentTestClass, ..CurrentTestMethod, AssertionType, Expected, Result, Description)
	Do ..Results.Insert(Info)
	Quit Info
}

/// Records a test skip.
Method RecordTestSkipped(Reason As %String = "") As Strix.Testing.Info
{
	Set ..Skipped = ..Skipped + 1
	Do ..ToTerm("S")
	Set Info = ##class(Strix.Testing.Info).Get("Skip", ..CurrentTestClass, ..CurrentTestMethod, , , , Reason)
	Do ..Results.Insert(Info)
	Quit Info
}

/// Records an error (e.g. trapped error, error status, etc.).
Method RecordError(Description As %String = "", Status As %Status = "") As Strix.Testing.Info
{
	Set ..Errors = ..Errors + 1
	Do ..ToTerm("E")
	Set Info = ##class(Strix.Testing.Info).GetForError(..CurrentTestClass, ..CurrentTestMethod, Description, Status)
	Do ..Results.Insert(Info)
	Quit Info
}

// =====

/// Writes what's passed in to the current device, if this is a terminal.
Method ToTerm(What As %String)
{
	If '$$$IsTerm Quit
	Write What
}

/// Writes test run results to the terminal
Method ReportToTerminal()
{
	If $X Write !
	Write !
	
	Set Duration = $System.SQL.DATEDIFF("second", ..TestRunStart, ..TestRunDone)
	Write "Tests started at "_$Piece(..TestRunStart, ".")_" and took "_Duration_" seconds.",!
	Write "Ran "_..Tests_" tests in "_..TestCases_" testcases.",!
	Write "A total of "_..Asserts_" assertions were successful; "_..Skipped_" were skipped.",!
	Write "There were "_..Failed_" failed assertions and "_..Errors_" errors.",!
	
	If '(..Failed+..Skipped+..Errors) Quit
	Write !,"Details below:",!
	
	; Width for test number
	Set w = $Length(..Results.Count())+2
	For i = 1:1:..Results.Count() {
		#dim Info As Strix.Testing.Info
		Set Info = ..Results.GetAt(i)
		If Info.Type = "Pass" {
			Continue
			Write !,"#"_i,?w,Info.ClassName_":"_Info.MethodName_": "_Info.Description,!
			If Info.BackgroundLocation '= "" Write ?w,"("_Info.BackgroundLocation_")",!
			Continue
		}
		
		Write !,"#"_i_" "_Info.ClassName_":"_Info.MethodName_":",!
		Do Info.ReportToTerminal()
	}
}

}

