<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Tests.StringList">
<Description>
Tests for class Strix.Lib.StringList.</Description>
<Super>Strix.Testing.TestCase</Super>
<TimeCreated>63646,55700.049068</TimeCreated>

<Method name="TestWithControlChars">
<Description>
Test control char roundtrip and escaping.</Description>
<Implementation><![CDATA[
	Set Text = ""
	For i = 0:1:$ZHex("9F") Set Text = Text_$Char(i)
	Set Input = $lb(Text)
	
	Set StringList = ##class(Strix.Lib.StringList).FromList(Input)
	Set CachéList = ##class(Strix.Lib.StringList).ToList(StringList)
	
	Do ..AssertListEqual(CachéList, Input)
	Do ..AssertFalse(StringList ? .E1.C.E, "Stringlist may not have control characters.")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestCreate">
<Description>
Test method Create.</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap", , "noot", "Mies")
	Set Expected = $lb("Aap", , "noot", "Mies")
	Set Result = ##class(Strix.Lib.StringList).ToList(StringList)
	Do ..AssertListEqual(Result, Expected)
	Quit
]]></Implementation>
</Method>

<Method name="TestExplode">
<Description>
Test method Explode.</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap", , "noot", "Mies")
	
	Set Status = ##class(Strix.Lib.StringList).Explode(StringList, .Items)
	Do ..AssertStatusOk(Status, "Explode should not return an error.")
	
	Do ..AssertEqual(Items, 4, "Explode should return 4 items.")
	Do ..AssertEqual(Items(1), "Aap")
	Do ..AssertFalse($Data(Items(2)), "Second item should be null.")
	Do ..AssertEqual(Items(3), "noot")
	Do ..AssertEqual(Items(4), "Mies")
	
	Set Back = ##class(Strix.Lib.StringList).Create(Items...)
	Do ..AssertEqual(Back, StringList, "Explode/create should round-trip properly.")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestEscape">
<Description>
Test escape/unescape roundtrip.</Description>
<Implementation><![CDATA[
	Set Text = ""
	For i = 0:1:$ZHex("11F") Set Text = Text_$Char(i)
	Set Escaped = ##class(Strix.Lib.StringList).Escape(Text)
	Set Unescaped = ##class(Strix.Lib.StringList).Unescape(Escaped)
	Do ..AssertEqual(Unescaped, Text, "Escape/unescape should round-trip properly.")
	Quit
]]></Implementation>
</Method>

<Method name="TestBackslash">
<Description>
Test handling of backslashes when escaping.</Description>
<Implementation><![CDATA[
	;If only a backslash is present it should not be escaped:
	Set Text = "\"
	Set Escaped = ##class(Strix.Lib.StringList).Escape(Text)
	Do ..AssertEqual(Escaped, Text, "Only backslash needs no escape.")
	
	;If also a control character is present the backslash should also be escaped:
	Set Text = "\"_$Char(10)
	Set Escaped = ##class(Strix.Lib.StringList).Escape(Text)
	Do ..AssertEqual(Escaped, "\5C\0A", "When escapes present backslash must also be escaped.")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestSubList">
<Description>
Test various sublist extractions.</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap", , "noot", "Mies")
	
	Set Sub = ##class(Strix.Lib.StringList).GetSubList(StringList, 1, 1)
	Set AsList = ##class(Strix.Lib.StringList).ToList(Sub)
	Do ..AssertListEqual(AsList, $lb("Aap"), "Sublist of one item should be a stringlist")
	
	Set Sub = ##class(Strix.Lib.StringList).GetSubList(StringList, 1)
	Set AsList = ##class(Strix.Lib.StringList).ToList(Sub)
	Do ..AssertListEqual(AsList, $lb("Aap"), "If To parameter missing, sublist should be length one")
	
	Set Sub = ##class(Strix.Lib.StringList).GetSubList(StringList, 1, 2)
	Set AsList = ##class(Strix.Lib.StringList).ToList(Sub)
	Do ..AssertListEqual(AsList, $lb("Aap", ), "Sublist of two items should be returned")
	
	Set Sub = ##class(Strix.Lib.StringList).GetSubList(StringList, 2, 4)
	Set AsList = ##class(Strix.Lib.StringList).ToList(Sub)
	Do ..AssertListEqual(AsList, $lb( , "noot", "Mies"), "Sublist of three items should be returned")
	
	Quit
]]></Implementation>
</Method>

<Method name="TestGetLength">
<Description>
Test method GetLength.</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap", , "noot", "Mies")
	Set Length = ##class(Strix.Lib.StringList).GetLength(StringList)
	Do ..AssertEqual(Length, 4)
	
	Set StringList = ##class(Strix.Lib.StringList).Create()
	Set Length = ##class(Strix.Lib.StringList).GetLength(StringList)
	Do ..AssertEqual(Length, 0)
	
	Quit
]]></Implementation>
</Method>

<Method name="TestCheck">
<Description>
Test method Check</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap, noot, Mies.")
	Do ##class(Strix.Lib.StringList).Check(StringList, .Status)
	Do ..AssertStatusOk(Status)
	
	Set Error = $Extract(StringList, 1, *-1)
	Do ##class(Strix.Lib.StringList).Check(Error, .Status)
	Do ..AssertErrorStatus(Status)
	
	Set Error = StringList_"x"
	Do ##class(Strix.Lib.StringList).Check(Error, .Status)
	Do ..AssertErrorStatus(Status)
	
	Set Error = "1"_StringList
	Do ##class(Strix.Lib.StringList).Check(Error, .Status)
	Do ..AssertErrorStatus(Status)
	
	Quit
]]></Implementation>
</Method>

<Method name="TestGetItem">
<Description>
Test method GetItem.</Description>
<Implementation><![CDATA[
	Set StringList = ##class(Strix.Lib.StringList).Create("Aap", , "noot", "Mies")
	
	;Normal item
	Set Item = ##class(Strix.Lib.StringList).GetItem(StringList, 1, "Default")
	Do ..AssertEqual(Item, "Aap")
	
	;Null item returns default value
	Set Item = ##class(Strix.Lib.StringList).GetItem(StringList, 2, "Default")
	Do ..AssertEqual(Item, "Default")
	
	;Index out of range: always return empty string, not default
	Set Item = ##class(Strix.Lib.StringList).GetItem(StringList, 0, "Default")
	Do ..AssertEqual(Item, "")
	
	;Index out of range: always return empty string, not default
	Set Item = ##class(Strix.Lib.StringList).GetItem(StringList, 10, "Default")
	Do ..AssertEqual(Item, "")
	
	Quit
]]></Implementation>
</Method>
</Class>
</Export>
