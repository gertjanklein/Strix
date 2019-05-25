<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.EAN">
<Description>
Tests EAN validators</Description>
<IncludeCode>Strix</IncludeCode>
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>63858,42156.198023</TimeCreated>

<Method name="Test13">
<Implementation><![CDATA[
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid13("0075678164125"), "Valid EAN-13 should return true.")
	Do ..AssertFalse(##class(Strix.Std.EAN).IsValid13("0075678164124"), "Invalid EAN-13 should return false.")
	
	; ISBN is an EAN-13 as well, but formatted with dashes
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid13("978-0-306-40615-7"), "Dash separators should be allowed.")
	
	Quit
]]></Implementation>
</Method>

<Method name="Test8">
<Implementation><![CDATA[
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid8("55123457"), "Valid EAN-8 should return true.")
	Do ..AssertFalse(##class(Strix.Std.EAN).IsValid8("55123456"), "Invalid EAN-8 should return false.")
	
	Quit
]]></Implementation>
</Method>
</Class>
</Export>
