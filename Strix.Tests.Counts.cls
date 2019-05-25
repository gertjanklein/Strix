Include Strix

Class Strix.Tests.Counts Extends Strix.Testing.TestCase
{

/// Various basic NLargest tests
Method TestNLargest()
{
	Set Values = $lb(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	
	#dim Counter As Strix.Lib.Counts
	Set Counter = ##class(Strix.Lib.Counts).NLargest(1)
	For i = 1:1:$ll(Values) { Set Value = $List(Values, i) Do Counter.Add(Value, "Value "_Value) }
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 1, "NLargest with MaxCount 1 should return 1 result.")
	Do ..AssertEqual($List($List(Result)), 10, "First returned result should be highest value.")
	
	Set Counter = ##class(Strix.Lib.Counts).NLargest(2)
	For i = 1:1:$ll(Values) { Set Value = $List(Values, i) Do Counter.Add(Value, "Value "_Value) }
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 2, "NLargest with MaxCount 2 should return 2 results.")
	Do ..AssertEqual($List($List(Result)), 10, "First returned result should be highest value.")
	Do ..AssertEqual($List($List(Result,2)), 9, "Second returned result should be second highest value.")
	
	Quit
}

/// Test that NLargest keeps the first name for a given value
Method TestNLargestKeepFirst()
{
	#dim Counter As Strix.Lib.Counts
	Set Counter = ##class(Strix.Lib.Counts).NLargest(5)
	For i = 1:1:5 Do Counter.Add(1, "Value "_i)
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 1, "NLargest with multiple equal counts should return 1 result.")
	Do ..AssertEqual($List($List(Result), 2), "Value 1", "Result should keep first encountered name.")
	
	Quit
}

// =====

/// Various basic NSmallest tests
Method TestNSmallest()
{
	Set Values = $lb(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	
	#dim Counter As Strix.Lib.Counts
	Set Counter = ##class(Strix.Lib.Counts).NSmallest(1)
	For i = 1:1:$ll(Values) { Set Value = $List(Values, i) Do Counter.Add(Value, "Value "_Value) }
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 1, "NSmallest with MaxCount 1 should return 1 result.")
	Do ..AssertEqual($List($List(Result)), 1, "First returned result should be smallest value.")
	
	Set Counter = ##class(Strix.Lib.Counts).NSmallest(2)
	For i = 1:1:$ll(Values) { Set Value = $List(Values, i) Do Counter.Add(Value, "Value "_Value) }
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 2, "NSmallest with MaxCount 2 should return 2 results.")
	Do ..AssertEqual($List($List(Result)), 1, "First returned result should be smallest value.")
	Do ..AssertEqual($List($List(Result,2)), 2, "Second returned result should be second smallest value.")
	
	Quit
}

/// Test that NSmallest keeps the first name for a given value
Method TestNSmallestKeepFirst()
{
	#dim Counter As Strix.Lib.Counts
	Set Counter = ##class(Strix.Lib.Counts).NSmallest(5)
	For i = 1:1:5 Do Counter.Add(1, "Value "_i)
	Set Result = Counter.GetList()
	Do ..AssertEqual($ListLength(Result), 1, "NSmallest with multiple equal counts should return 1 result.")
	Do ..AssertEqual($List($List(Result), 2), "Value 1", "Result should keep first encountered name.")
	
	Quit
}

// =====

/// Test method GetNext.
Method TestGetNext()
{
	Set Values = $lb(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	
	#dim Counter As Strix.Lib.Counts
	Set MaxCount = 2
	Set Counter = ##class(Strix.Lib.Counts).NLargest(MaxCount)
	For i = 1:1:$ll(Values) { Set Value = $List(Values, i) Do Counter.Add(Value, "Value "_Value) }
	
	Set Count = ""
	For i = 1:1 {
		Set Name = Counter.GetNext(.Count)
		If Count = "" Quit
		Do ..AssertEqual(Count, 11 - i, "GetNext result should be sequential.")
		Do ..AssertEqual(Name, "Value "_Count, "GetNext result should have proper name.")
	}
	Do ..AssertEqual(i, MaxCount + 1, "GetNext should be successfull "_MaxCount_" times.")
	
	Quit
}

}

