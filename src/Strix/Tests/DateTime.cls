/// Tests the DataTime datatype.
Class Strix.Tests.DateTime Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.DateTimeTest";

/// Code to run before any test in this class is executed.
Method Setup() As %Status
{
	;Create a persistent, XML-enabled class with properties of type DateTime for testing.
	
	#dim ClassDef As %Dictionary.ClassDefinition
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%Persistent,%XML.Adaptor", .ClassDef)
	If 'Status Quit Status
	
	Set Property = ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop1", "Strix.Lib.DateTime")
	Do Property.Parameters.SetAt("IGNORE", "XMLTIMEZONE")
	
	Set Property = ##class(Strix.Testing.Support).AddProperty(ClassDef, "Prop2", "Strix.Lib.DateTime")
	Do Property.Parameters.SetAt("UTC", "XMLTIMEZONE")
	
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Code to run after all tests in this class have been executed.
Method TearDown() As %Status
{
	Quit ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
}

// =====

/// Test that values are stored as $Horolog-type strings
Method TestStorage()
{
	Set DateTime = $Horolog
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.Prop1 = DateTime
	Set Obj.Prop2 = DateTime
	
	Set Status = Obj.%Save()
	If '..AssertStatusOk(Status, "Should be able to save test object.") Quit
	
	Set Id = Obj.%Id()
	
	Do ..AssertEqual(Obj.Prop1GetStored(Id), DateTime, "Stored value of Prop1")
	Do ..AssertEqual(Obj.Prop2GetStored(Id), DateTime, "Stored value of Prop2")
	
	;Clear test object
	Do Obj.%DeleteId(Obj.%Id())
	
	Quit
}

/// Test that values output to XML properly
Method TestXMLOutput()
{
	Set DateTime = $ZDateTimeH("2015-11-07 12:33:00", 3, 1)
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	Set Obj.Prop1 = DateTime
	Set Obj.Prop2 = DateTime
	
	Set XML = ""
	Set Status = Obj.XMLExportToString(.XML)
	If '..AssertStatusOk(Status, "Should be able to export test object to XML.") Quit
	
	;Prop1, with timezone ignore, should generate a naive datetime (no zone spec)
	Do ..AssertContains(XML, "<Prop1>2015-11-07T12:33:00</Prop1>", "Generated XML should contain proper value for Prop1.")
	
	;Prop2, with timezone UTC, should generate a datetime with timezone UTC
	Do ..AssertContains(XML, "<Prop2>2015-11-07T12:33:00Z</Prop2>", "Generated XML should contain proper value for Prop2.")
	
	Quit
}

/// Test that values input from XML properly
Method TestXMLInput()
{
	Set DateTimeString = "2015-11-07T12:33:00"
	Set DateTime = $ZDateTimeH(DateTimeString, 3, 1)
	
	Set Reader = ##class(%XML.Reader).%New()
	Do Reader.Correlate("DateTimeTest", ..#TestClassName)
	
	;===== Prop1: XML timezone ignore
	
	Set XML = "<DateTimeTest><Prop1>"_DateTimeString_"</Prop1></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(Obj.Prop1, DateTime, "Prop1, no timezone spec")
	}
	
	Set XML = "<DateTimeTest><Prop1>"_DateTimeString_"Z</Prop1></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(Obj.Prop1, DateTime, "Prop1, UTC timezone spec")
	}
	
	Set XML = "<DateTimeTest><Prop1>"_DateTimeString_"+03:00</Prop1></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(Obj.Prop1, DateTime, "Prop1, timezone offset")
	}
	
	;===== Prop2: XML timezone UTC
	
	Set XML = "<DateTimeTest><Prop2>"_DateTimeString_"</Prop2></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(Obj.Prop2, DateTime, "Prop2, no timezone spec")
	}
	
	Set XML = "<DateTimeTest><Prop2>"_DateTimeString_"Z</Prop2></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(Obj.Prop2, DateTime, "Prop2, UTC timezone spec")
	}
	
	Set XML = "<DateTimeTest><Prop2>"_DateTimeString_"+03:00</Prop2></DateTimeTest>"
	Set Status = Reader.OpenString(XML)
	If '..AssertStatusOk(Status, "XML Reader OpenString() should not return an error.") Quit
	If ..AssertTrue(Reader.Next(.Obj, .Status), "XML Reader should find object.") {
		If '..AssertStatusOk(Status, "XML Reader Next() should not return an error.") Quit
		Do ..AssertEqual(+Obj.Prop2, +DateTime, "Date part of datetime with timezone offset.")
		Set Got = $ZTime($Piece(Obj.Prop2, ",", 2), 1)
		Set Expected = $ZTime($Piece(DateTime, ",", 2) - (3 * 3600), 1)
		Do ..AssertEqual(Got, Expected, "Time part of datetime with timezone offset.")
	}
	
	Quit
}

// =====

/// Test property method OdbcToLogical
Method TestOdbcToLogical()
{
	Set DateTimeString = "2015-11-07 12:33:00"
	Set DateTime = $ZDateTimeH(DateTimeString, 3, 1)
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	
	Set Test = Obj.Prop1OdbcToLogical(DateTimeString)
	Do ..AssertEqual(Test, DateTime, "OdbcToLogical property method.")
	
	Set Test = Obj.Prop1OdbcToLogical("x"_DateTimeString)
	Do ..AssertEqual(Test, "", "OdbcToLogical property method on invalid input.")
	
	Set Test = Obj.Prop1OdbcToLogical("")
	Do ..AssertEqual(Test, "", "OdbcToLogical property method on empty input.")
	
	Quit
}

/// Test property method LogicalToOdbc
Method TestLogicalToOdbc()
{
	Set DateTimeString = "2015-11-07 12:33:00"
	Set DateTime = $ZDateTimeH(DateTimeString, 3, 1)
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	
	Set Test = Obj.Prop1LogicalToOdbc(DateTime)
	Do ..AssertEqual(Test, DateTimeString, "LogicalToOdbc property method.")
	
	Set Test = Obj.Prop1LogicalToOdbc(999999_DateTime)
	Do ..AssertEqual(Test, "", "LogicalToOdbc property method on invalid input.")
	
	Set Test = Obj.Prop1LogicalToOdbc("")
	Do ..AssertEqual(Test, "", "LogicalToOdbc property method on empty input.")
	
	Quit
}

// =====

/// Test property method DisplayToLogical
Method TestDisplayToLogical()
{
	Set DateTimeString = "2015-11-07 12:33:00"
	Set DateTime = $ZDateTimeH(DateTimeString, 3, 1)
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	
	Set Test = Obj.Prop1DisplayToLogical(DateTimeString)
	Do ..AssertEqual(Test, DateTime, "OdbcToLogical property method.")
	
	Set Test = Obj.Prop1DisplayToLogical("x"_DateTimeString)
	Do ..AssertEqual(Test, "", "OdbcToLogical property method on invalid input.")
	
	Set Test = Obj.Prop1DisplayToLogical("")
	Do ..AssertEqual(Test, "", "OdbcToLogical property method on empty input.")
	
	Quit
}

/// Test property method LogicalToDisplay
Method TestLogicalToDisplay()
{
	Set DateTimeString = "2015-11-07 12:33:00"
	Set DateTime = $ZDateTimeH(DateTimeString, 3, 1)
	
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	
	Set Test = Obj.Prop1LogicalToDisplay(DateTime)
	Do ..AssertEqual(Test, DateTimeString, "LogicalToOdbc property method.")
	
	Set Test = Obj.Prop1LogicalToDisplay(999999_DateTime)
	Do ..AssertEqual(Test, "", "LogicalToOdbc property method on invalid input.")
	
	Set Test = Obj.Prop1LogicalToDisplay("")
	Do ..AssertEqual(Test, "", "LogicalToOdbc property method on empty input.")
	
	Quit
}

// =====

/// Test property method IsValid
Method TestIsValid()
{
	#dim Obj As Strix.Tests.Temp.DateTimeTest
	Set Obj = $ZObjClassMethod(..#TestClassName, "%New")
	
	;Valid inputs
	Do ..AssertStatusOk(Obj.Prop2IsValid($Horolog), "With $Horolog value")
	Do ..AssertStatusOk(Obj.Prop2IsValid(""), "With empty value")
	
	;Invalid inputs
	Do ..AssertErrorStatus(Obj.Prop2IsValid("9999999"), "With x value")
	
	Quit
}

}
