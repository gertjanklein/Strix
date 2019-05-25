<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.Status">
<Description>
Test code for class Strix.Lib.Status</Description>
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>63863,82042.977252</TimeCreated>

<Method name="TestMessageWithParameters">
<Implementation><![CDATA[
	Set Message = "Testing {} {} '{}'"
	Set Status = $System.Status.Error($$$GeneralError, "Second error")
	Set Result = ##class(Strix.Lib.Status).BuildStatus(Message, Status, "one", "two", "three")
	Set sc = $System.Status.DecomposeStatus(Result, .e, "-d", "en")
	
	Do ..AssertStatusOk(sc, "Status should be valid")
	If '..AssertEqual($Get(e), 2, "Status should contain two errors") Quit
	Do ..AssertEqual(e(1), "ERROR #5001: Testing one two 'three'", "First message in status should match")
	Do ..AssertEqual(e(2), "ERROR #5001: Second error", "Second message in status should match")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestSingleMessage">
<Implementation><![CDATA[
	Set Message = "Testing"
	Set Result = ##class(Strix.Lib.Status).BuildStatus(Message)
	Set sc = $System.Status.DecomposeStatus(Result, .e, "-d", "en")
	
	Do ..AssertStatusOk(sc, "Status should be valid")
	If '..AssertEqual($Get(e), 1, "Status should contain one error") Quit
	Do ..AssertEqual(e(1), "ERROR #5001: Testing", "Message in status should match")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestSingleMessageWithParameters">
<Implementation><![CDATA[
	Set Message = "Testing {1} {2} '{3}'"
	Set Result = ##class(Strix.Lib.Status).BuildStatus(Message, , "one", "two", "three")
	Set sc = $System.Status.DecomposeStatus(Result, .e, "-d", "en")
	
	Do ..AssertStatusOk(sc, "Status should be valid")
	If '..AssertEqual($Get(e), 1, "Status should contain one error") Quit
	Do ..AssertEqual(e(1), "ERROR #5001: Testing one two 'three'", "Message in status should match")
	
	Quit
]]></Implementation>
</Method>
</Class>
</Export>
