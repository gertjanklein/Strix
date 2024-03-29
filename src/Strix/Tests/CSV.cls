/// Tests Strix.CSV.Parser.
Class Strix.Tests.CSV Extends Strix.Testing.TestCase
{

Parameter TestClassName = "Strix.Tests.Temp.CSVAdaptorTest";

/// Stream to use as input to parser
Property Stream As %GlobalCharacterStream;

// ===== Tests

/// Test basic functionality
Method TestBasic()
{
	Do ..MakeStream("a,b,c", "1,2,3")
	
	#dim p As Strix.CSV.Parser
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "a", "Result {} should have expected value.", 1)
	Do ..AssertEqual(p.Get(2), "b", "Result {} should have expected value.", 2)
	Do ..AssertEqual(p.Get(3), "c", "Result {} should have expected value.", 3)
	
	If '..Assert(p.Next(.Status), "Second row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "1", "Result {} should have expected value.", 1)
	Do ..AssertEqual(p.Get(2), "2", "Result {} should have expected value.", 2)
	Do ..AssertEqual(p.Get(3), "3", "Result {} should have expected value.", 3)
	
	If '..Assert('p.Next(.Status), "No third row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

/// Test header skipping functionality
Method TestSkip()
{
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	
	; Test skipping first row
	
	#dim p As Strix.CSV.Parser
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream,,1)
	
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "1", "Result {} should have expected value.", 1)
	Do ..AssertEqual(p.Get(2), "2", "Result {} should have expected value.", 2)
	Do ..AssertEqual(p.Get(3), "3", "Result {} should have expected value.", 3)
	
	If '..Assert(p.Next(.Status), "Second row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	
	If '..Assert('p.Next(.Status), "No third row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	;Test skipping all rows
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream,,3)
	If '..Assert('p.Next(.Status), "No rows should be found when skipping all.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

/// Test different separator
Method TestSeparator()
{
	Do ..MakeStream("a;b;c", "1;2,a;3", "4;5;6")
	
	#dim p As Strix.CSV.Parser
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, ";")
	
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	
	If '..Assert(p.Next(.Status), "Second row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "1", "Result {} should have expected value.", 1)
	Do ..AssertEqual(p.Get(2), "2,a", "Result {} should have expected value.", 2)
	Do ..AssertEqual(p.Get(3), "3", "Result {} should have expected value.", 3)
	
	If '..Assert(p.Next(.Status), "Third row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still ok.")
	
	If '..Assert('p.Next(.Status), "No fourth row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

/// Test quoted fields
Method TestQuoteSimple()
{
	Do ..MakeStream("1,""x,y,z"",3", "4,5,""6,""", """9"",""8"",""7""", """"""""",b,c")
	
	#dim p As Strix.CSV.Parser
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	
	If '..Assert(p.Next(.Status), "Record {} should be found.", p.RecordNr) Quit
	Do ..AssertStatusOk(Status, "Returned status for record {} should be ok.", p.RecordNr)
	Do ..AssertEqual(p.Data, 3, "Record {} should have expected number of columns.", p.RecordNr)
	Do ..AssertEqual(p.Get(1), "1", "Record {}, field 1 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(2), "x,y,z", "Record {}, field 2 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(3), "3", "Record {}, field 3 should have expected value.", p.RecordNr)
	
	If '..Assert(p.Next(.Status), "Record {} should be found.", p.RecordNr) Quit
	Do ..AssertStatusOk(Status, "Returned status for record {} should be ok.", p.RecordNr)
	Do ..AssertEqual(p.Data, 3, "Record {} should have expected number of columns.", p.RecordNr)
	Do ..AssertEqual(p.Get(1), "4", "Record {}, field 1 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(2), "5", "Record {}, field 2 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(3), "6,", "Record {}, field 3 should have expected value.", p.RecordNr)
	
	If '..Assert(p.Next(.Status), "Record {} should be found.", p.RecordNr) Quit
	Do ..AssertStatusOk(Status, "Returned status for record {} should be ok.", p.RecordNr)
	Do ..AssertEqual(p.Data, 3, "Record {} should have expected number of columns.", p.RecordNr)
	Do ..AssertEqual(p.Get(1), "9", "Record {}, field 1 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(2), "8", "Record {}, field 2 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(3), "7", "Record {}, field 3 should have expected value.", p.RecordNr)
	
	If '..Assert(p.Next(.Status), "Record {} should be found.", p.RecordNr) Quit
	Do ..AssertStatusOk(Status, "Returned status for record {} should be ok.", p.RecordNr)
	Do ..AssertEqual(p.Data, 3, "Record {} should have expected number of columns.", p.RecordNr)
	Do ..AssertEqual(p.Get(1), """", "Record {}, field 1 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(2), "b", "Record {}, field 2 should have expected value.", p.RecordNr)
	Do ..AssertEqual(p.Get(3), "c", "Record {}, field 3 should have expected value.", p.RecordNr)
	
	If '..Assert('p.Next(.Status), "No more rows should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

/// Test multiline quoted fields
Method TestMultiline()
{
	#dim p As Strix.CSV.Parser
	
	; Field 2 split over 3 lines
	
	Do ..MakeStream("1,""This is"_$$$EOL_"a multiline"_$$$EOL_"field."",3")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "1", "Result 1 should have expected value.")
	Do ..AssertEqual(p.Get(2), "This is"_$$$EOL_"a multiline"_$$$EOL_"field.", "Result 2 should have expected value.")
	Do ..AssertEqual(p.Get(3), "3", "Result 3 should have expected value.")
	
	; Last field ends in newlines
	
	Do ..MakeStream("""Newlines: "_$$$EOL_$$$EOL_"""")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 1, "Result should have expected number of columns.")
	Do ..AssertEqual(p.Get(1), "Newlines: "_$$$EOL_$$$EOL, "Result should have expected value.")
	
	Quit
}

/// Test unparseable data
Method TestErrors()
{
	#dim p As Strix.CSV.Parser
	
	; Lone quote in quoted field
	
	Do ..MakeStream("1,""before""after"",3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	Do ..AssertFalse(p.Next(.Status), "First row should not be found.")
	Do ..AssertErrorStatus(Status, "Returned status should be an error.")
	
	; End of data searching for close quote
	
	Do ..MakeStream("1,""")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	Do ..AssertFalse(p.Next(.Status), "First row should not be found.")
	Do ..AssertErrorStatus(Status, "Returned status should be an error.")
	
	Do ..MakeStream("1,"""_$$$EOL_$$$EOL)
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	Do ..AssertFalse(p.Next(.Status), "First row should not be found.")
	Do ..AssertErrorStatus(Status, "Returned status should be an error.")
	
	
	Quit
}

/// Test retrieving column by name
Method TestByName()
{
	#dim p As Strix.CSV.Parser
	
	; Take column names from first row if skipcount is precisely 1
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1)
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.GetByName("a"), "1", "Result a should have expected value.")
	Do ..AssertEqual(p.GetByName("b"), "2", "Result b should have expected value.")
	Do ..AssertEqual(p.GetByName("c"), "3", "Result c should have expected value.")
	
	; ...unless this is explicitly turned off
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1, "")
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.GetByName("a"), "", "Column 1 should not be found by name.")
	Do ..AssertEqual(p.GetByName("b"), "", "Column 2 should not be found by name.")
	Do ..AssertEqual(p.GetByName("c"), "", "Column 3 should not be found by name.")
	
	; Columns names set manually
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1, "x,y,z")
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.GetByName("x"), "1", "Column 1 should be accessible by name x.")
	Do ..AssertEqual(p.GetByName("y"), "2", "Column 2 should be accessible by name y.")
	Do ..AssertEqual(p.GetByName("z"), "3", "Column 3 should be accessible by name z.")
	
	; Not all names need to be present
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1, "x,,z")
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertEqual(p.Data, 3, "Result should have expected number of columns.")
	Do ..AssertEqual(p.GetByName("x"), "1", "Column 1 should be accessible by name x.")
	Do ..AssertEqual(p.Get(2), "2", "Column 2 should be accessible by column number.")
	Do ..AssertEqual(p.GetByName("z"), "3", "Column 3 should be accessible by name z.")
	
	
	Quit
}

/// Test GetAsList
Method TestGetAsList()
{
	#dim p As Strix.CSV.Parser
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream)
	
	If '..Assert(p.Next(.Status), "First row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertListEqual(p.GetAsList(), $lfs("a,b,c"), "GetAsList should return the proper data.")
	
	If '..Assert(p.Next(.Status), "Second row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertListEqual(p.GetAsList(), $lfs("1,2,3"), "GetAsList should return the proper data.")
	
	If '..Assert(p.Next(.Status), "Third row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should be ok.")
	Do ..AssertListEqual(p.GetAsList(), $lfs("4,5,6"), "GetAsList should return the proper data.")
	
	If '..Assert('p.Next(.Status), "No fourth row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

// =====

/// Basic test of retrieving a Strix.CSV.Adaptor object from the parser.
Method TestAdaptor()
{
	#dim p As Strix.CSV.Parser
	
	Set Status = ..CreateClass("PropA::a,PropB::b,PropC::c")
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	
	Do ..MakeStream("a,b,c", "1,2,3", "4,5,6")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1)
	Set p.AdaptorClassName = ..#TestClassName
	
	If '..Assert(p.Next(.Status), "First record should be found.") Quit
	Set Obj = p.GetObject(.Status)
	If '..AssertStatusOk(Status, "Should be able to get object.") Quit
	Do ..AssertEqual(Obj.PropA, 1, "Property a should be loaded.")
	Do ..AssertEqual(Obj.PropB, 2, "Property b should be loaded.")
	Do ..AssertEqual(Obj.PropC, 3, "Property c should be loaded.")
	
	If '..Assert(p.Next(.Status), "Second record should be found.") Quit
	Set Obj = p.GetObject(.Status)
	If '..AssertStatusOk(Status, "Should be able to get object.") Quit
	Do ..AssertEqual(Obj.PropA, 4, "Property a should be loaded.")
	Do ..AssertEqual(Obj.PropB, 5, "Property b should be loaded.")
	Do ..AssertEqual(Obj.PropC, 6, "Property c should be loaded.")
	
	If '..Assert('p.Next(.Status), "No next row should be found.") Quit
	Do ..AssertStatusOk(Status, "Returned status should still be ok.")
	
	Quit
}

/// Test default adaptor datatype conversions
Method TestAdaptorDataType()
{
	#dim p As Strix.CSV.Parser
	
	Set Status = ..CreateClass("PropA:%Date:a,PropB:%Boolean:b,PropC:%Numeric:c,PropD:%Time:d")
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	
	Do ..MakeStream("a,b,c,d", "1961-06-22,yes,1.000,12:13:22")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1)
	Set p.AdaptorClassName = ..#TestClassName
	
	If '..Assert(p.Next(.Status), "Record should be found.") Quit
	Set Obj = p.GetObject(.Status)
	If '..AssertStatusOk(Status, "Should be able to get object.") Quit
	Do ..AssertEqual(Obj.PropA, 44002, "Property a should be converted.")
	Do ..AssertEqual(Obj.PropB, 1, "Property b should be converted.")
	Do ..AssertEqual(Obj.PropC, 1, "Property c should be converted.")
	Do ..AssertEqual(Obj.PropD, 44002, "Property d should be converted.")
	
	Quit
}

/// Test datatype conversion override by subclassing and changing parameter
Method TestAdaptorDataTypeExpression()
{
	#dim cd As %Dictionary.ClassDefinition
	Set Status = ..CreateClass("PropA:%Date:a", .cd)
	If '..AssertStatusOk(Status, "Should be able to create a test class.") Quit
	Do ##class(Strix.Testing.Support).SetClassParameter(cd, "DateExpression", "$ZDateH($Translate(v,""-"",""/""),4)")
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(cd)
	If '..AssertStatusOk(Status, "Should be able to update test class.") Quit
	
	#dim p As Strix.CSV.Parser
	
	Do ..MakeStream("a", "22-06-1961")
	Set p = ##class(Strix.CSV.Parser).GetParser(..Stream, , 1)
	Set p.AdaptorClassName = ..#TestClassName
	
	If '..Assert(p.Next(.Status), "Record should be found.") Quit
	Set Obj = p.GetObject(.Status)
	If '..AssertStatusOk(Status, "Should be able to get object.") Quit
	Do ..AssertEqual(Obj.PropA, 44002, "Property should be converted.")
	
	Quit
}

// ===== Helpers

Method MakeStream(Lines... As %String)
{
	Do ..Stream.Clear()
	For i = 1:1:$Get(Lines) {
		Do ..Stream.WriteLine($Get(Lines(i)))
	}
	Do ..Stream.Rewind()
}

/// Create a class with the specified properties
ClassMethod CreateClass(Properties As %String = "", Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	Set Status = ##class(Strix.Testing.Support).CreateClass(..#TestClassName, "%RegisteredObject,Strix.CSV.Adaptor", .ClassDef)
	If 'Status Quit Status
	Set Status = ##class(Strix.Testing.Support).SetClassParameter(ClassDef, "PreferredLoader", "header")
	If 'Status Quit Status
	
	If Properties '= "" {
		For i = 1:1:$Length(Properties, ",") {
			Set Def = $Piece(Properties, ",", i)
			Set Name = $Piece(Def, ":", 1)
			Set Type = $Piece(Def, ":", 2)
			If Type = "" Set Type = "%String"
			Set ColumnHeader = $Piece(Def, ":", 3)
			
			#dim pd As %Dictionary.PropertyDefinition
			Set pd = ##class(Strix.Testing.Support).AddProperty(ClassDef, Name, Type)
			Do pd.Parameters.SetAt(ColumnHeader, "CsvColumnHeader")
		}
	}
	
	Set Status = ##class(Strix.Testing.Support).SaveAndCompile(ClassDef)
	If 'Status Quit Status
	
	Quit $$$OK
}

// ===== Cleanup code.

/// Code to run after all tests in this class have been executed.
Method TearDown(FailedTests As %String) As %Status
{
	If FailedTests '= "" Quit $$$OK
	Set Status = ##class(Strix.Testing.Support).RemoveClass(..#TestClassName)
	If 'Status Quit Status
	Quit $$$OK
}

}
