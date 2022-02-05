/// Test code for class Strix.Lib.String
Class Strix.Tests.String Extends Strix.Testing.TestCase
{

Method TestTemplateReplace()
{
	Set Template = "{}{}{}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, "a", "b", "c")
	Do ..AssertEqual(Result, "abc", "Basic sequential replacement.")
	
	Set Template = "{}{}{}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, $ListBuild("a", "b", "c"))
	Do ..AssertEqual(Result, "abc", "Parameters as %List.")
	
	Set Template = "{3}{2}{1}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, "a", "b", "c")
	Do ..AssertEqual(Result, "cba", "Basic reversed replacement.")
	
	Set Template = "{1}{}{3}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, "a", "b", "c")
	Do ..AssertEqual(Result, "abc", "With and without position specifier.")
	
	Set Template = "{1}{{}{3}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, "a", "b", "c")
	Do ..AssertEqual(Result, "a{}c", "Brace escape.")
	
	Set Template = "{1}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, "a", "b", "c")
	Do ..AssertEqual(Result, "a", "Ignore extraneous parameters.")
	
	Set Template = "{1}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, $ListBuild("a", "b", "c"))
	Do ..AssertEqual(Result, "a", "Ignore extraneous parameters in %List.")
	
	Quit
}

Method TestTemplateReplaceKwArgs()
{
	; Keyword argument
	Set Template = "{a}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, {"a":42})
	Do ..AssertEqual(Result, "42", "Basic keyword argument replacement.")
	
	; Keyword arguments in order
	Set Template = "{a}{b}{c}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, {"c":1, "b":2, "a":42})
	Do ..AssertEqual(Result, "4221", "Basic keyword argument replacement.")
	
	; Keyword combined with regular arguments
	Set Template = "{a}{}{c}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, {"a":42}, "this is b", {"c":52})
	Do ..AssertEqual(Result, "42this is b52", "Basic keyword argument replacement.")
	
	; Keyword arguments merging
	Set Template = "{a}{b}{c}"
	Set Result = ##class(Strix.Lib.String).TemplateReplace(Template, {"a":42}, {"a":1, "c":42})
	Do ..AssertEqual(Result, "142", "Basic keyword argument replacement.")
	
	Quit
}

Method TestListObjToString()
{
	Set List = ##class(%ListOfDataTypes).%New()
	
	Set Result = ##class(Strix.Lib.String).ListObjToString(List)
	Do ..AssertEqual(Result, "", "Empty list returns empty result.")
	
	Set Result = ##class(Strix.Lib.String).ListObjToString(List, "")
	Do ..AssertEqual(Result, "", "Empty list returns empty %List result.")
	
	Do List.Insert("a"), List.Insert("b"), List.Insert("c")
	
	Set Result = ##class(Strix.Lib.String).ListObjToString(List)
	Do ..AssertEqual(Result, "a,b,c", "Proper comma-separated result.")
	
	Set Result = ##class(Strix.Lib.String).ListObjToString(List, ";")
	Do ..AssertEqual(Result, "a;b;c", "Proper result with alternate separator.")
	
	Set Result = ##class(Strix.Lib.String).ListObjToString(List, "")
	Do ..AssertListEqual(Result, $ListFromString("a,b,c"), "Proper result as %List.")
	
	Quit
}

Method TestListObjFromString()
{
	#dim List As %Collection.AbstractListOfDT
	
	Do ##class(Strix.Lib.String).ListObjFromString("", , .List)
	If '..Assert($IsObject(List), "Method should return an object.") Quit
	Do ..AssertEqual(List.Count(), 0, "Result should be empty.") Quit
	Kill List
	
	Set List = ##class(%ListOfDataTypes).%New(), Oref = ""_List
	Do ##class(Strix.Lib.String).ListObjFromString("", , .List)
	Do ..AssertEqual(""_List, Oref, "If object passed in it should be used.") Quit
	Kill List
	
	Set Input = "a,b,c"
	
	Do ##class(Strix.Lib.String).ListObjFromString(Input, , .List)
	Do ..AssertEqual(List.Count(), 3, "Items should be split properly.")
	Do ..AssertEqual(List.GetAt(1), "a", "Items should be split properly.")
	Do ..AssertEqual(List.GetAt(2), "b", "Items should be split properly.")
	Do ..AssertEqual(List.GetAt(3), "c", "Items should be split properly.")
	
	Do ##class(Strix.Lib.String).ListObjFromString(Input, " ", .List)
	Do ..AssertEqual(List.Count(), 1, "Items should not be split.")
	Do ..AssertEqual(List.GetAt(1), Input, "First item should be unchanged input.")
	
	Do ##class(Strix.Lib.String).ListObjFromString($ListFromString(Input), " ", .List)
	Do ..AssertEqual(List.Count(), 3, "%List should be automatically recognised.")
	
	Quit
}

/// Minimal tests for the RxReplace method.
Method TestRxReplace()
{
	; Test simple backref
	Set Result = ##class(Strix.Lib.String).RxReplace("XnXValue", "^XnX(.*)", "$1")
	Do ..AssertEqual(Result, "Value", "Backreference works.")
	
	; Test replace alternatives
	Set Result = ##class(Strix.Lib.String).RxReplace("blue socks and red shoes", "(blue|white|red)", "coloured")
	Do ..AssertEqual(Result, "coloured socks and coloured shoes", "Replace alternatives works.")
	
	; Test nested group
	Set Result = ##class(Strix.Lib.String).RxReplace("Weather report", "(.* (report))", "$1 $2")
	Do ..AssertEqual(Result, "Weather report report", "Nested backreferences work.")
	
	; Test nested group with alternatives
	Set Result = ##class(Strix.Lib.String).RxReplace("The blue parrot", "(.*(blue|white|red).*)", "$1 is $2")
	Do ..AssertEqual(Result, "The blue parrot is blue", "Nested backreferences work.")
	
	; Test default case sensitivity
	Set Result = ##class(Strix.Lib.String).RxReplace("The Blue parrot", "(.*(blue|white|red).*)", "$1 is $2")
	Do ..AssertEqual(Result, "The Blue parrot", "Matching is case sensitive by default.")
	
	; Test replace case insensitively
	Set Result = ##class(Strix.Lib.String).RxReplace("The Blue parrot", "(?i)(.*(blue|white|red).*)", "$1 is $2")
	Do ..AssertEqual(Result, "The Blue parrot is Blue", "Matching is case sensitive by default.")
	
	Quit
}

/// Do ##class(Strix.Testing.Runner).Run("Strix.Tests.String:TestRemoveFromList")
Method TestRemoveFromList()
{
	Set Input = "a,b,c"
	
	Set Result = ##class(Strix.Lib.String).RemoveFromList(Input, ,"b", .Found)
	Do ..Assert(Found, "The string to remove was found")
	Do ..AssertEqual(Result, "a,c", "Entry in middle is removed")
	
	Set Result = ##class(Strix.Lib.String).RemoveFromList(Input, ,"a", .Found)
	Do ..Assert(Found, "The string to remove was found")
	Do ..AssertEqual(Result, "b,c", "Entry at start is removed")
	
	Set Result = ##class(Strix.Lib.String).RemoveFromList(Input, ,"c", .Found)
	Do ..Assert(Found, "The string to remove was found")
	Do ..AssertEqual(Result, "a,b", "Entry at end is removed")
	
	Set Result = ##class(Strix.Lib.String).RemoveFromList(Input, ,"d", .Found)
	Do ..Assert('Found, "The string to remove was not found")
	Do ..AssertEqual(Result, Input, "Input is unchanged")
	
	Set Result = ##class(Strix.Lib.String).RemoveFromList("", ,"", .Found)
	Do ..Assert('Found, "No replacement on empty input")
	Do ..AssertEqual(Result, "", "Input is unchanged")
	
	Quit
}

}

