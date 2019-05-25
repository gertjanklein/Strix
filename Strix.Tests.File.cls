<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.File">
<Description>
Tests for Strix.Lib.File</Description>
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>64293,51004.167135</TimeCreated>

<Method name="TestPathIsAbsolute">
<Implementation><![CDATA[
	
#if $$$isWINDOWS
	Do ..AssertTrue(##class(Strix.Lib.File).IsPathAbsolute("C:\Temp"), "Path rooted from drive should return true")
	Do ..AssertFalse(##class(Strix.Lib.File).IsPathAbsolute("C:Temp"), "Drive without root path should return false")
	
	Do ..AssertTrue(##class(Strix.Lib.File).IsPathAbsolute("\Temp", 1), "Unspecified drive should return true")
	Do ..AssertFalse(##class(Strix.Lib.File).IsPathAbsolute("\Temp", 0), "Unspecified drive should return false")
	
	Do ..AssertTrue(##class(Strix.Lib.File).IsPathAbsolute("\\Temp\a", 1), "Network path should return true")
	
#elseif $$$isUNIX
	Do ..AssertTrue(##class(Strix.Lib.File).IsPathAbsolute("/etc"), "Absolute path should return true")
	Do ..AssertFalse(##class(Strix.Lib.File).IsPathAbsolute("etc"), "Relative path should return false")
	
#else
	Do ..Skipped("Unrecognised operating system "_$ZVersion(1))
	
#endif
]]></Implementation>
</Method>
</Class>
</Export>
