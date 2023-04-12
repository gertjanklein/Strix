/// Various string manipulation methods.
Class Strix.Lib.String Extends %RegisteredObject
{

/// Converts a piece-separated string to individual pieces, indexed sequentially.
ClassMethod Explode(Input As %String, Separator As %String, Output Pieces As %String)
{
	Kill Pieces
	Set Pieces = 0
	
	If Input = "" Quit
	
	For i = 1:1:$Length(Input, Separator) {
		Set Pieces($Increment(Pieces)) = $Piece(Input, Separator, i)
	}
	
	Quit
}

/// Converts the keys of an array to a %List or (if Separator is not empty)
/// a piece-separated string.
ClassMethod ListFromArray(ByRef Array As %String, Separator As %String = ",") As %String
{
	Set Result = ""
	Set Key = ""
	For  {
		Set Key = $Order(Array(Key))
		If Key = "" Quit
		Set Result = Result_$ListBuild(Key)
	}
	
	If Separator '= "" Set Result = $ListToString(Result, Separator)
	
	Quit Result
}

/// Splits a string containing newlines into a list of lines. StripCfg
/// configures how whitespace in the lines is handled; if empty it is left
/// untouched.
ClassMethod SplitLines(Input As %String, StripCfg As %String = ">WC", SkipEmptyLines As %Boolean = 0) As %ListOfDataTypes
{
	Set Result = ##class(%ListOfDataTypes).%New()
	For i = 1:1:$Length(Input, $Char(10)) {
		Set Line = $Piece(Input, $Char(10), i)
		If StripCfg '= "" Set Line = $ZStrip(Line, StripCfg)
		If SkipEmptyLines, Line = "" Continue
		Do Result.Insert(Line)
	}
	Quit Result
}

/// Replaces parameter references in property Text with their values in property Parameters.
/// 
/// Parameter references use braces, as in:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {1}{2}{3}", "a", "b", "c")
/// The number between the braces is the parameter number, and is optional if
/// this number would equal the parameter reference number. The following example
/// therefore gives the same result as the previous one:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {1}{}{3}", "a", "b", "c")
/// and this example as well:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {}{}{}", "a", "b", "c")
/// 
/// Values may be passed in as multiple method parameters, e.g.:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, "a", "b", "c", ...)
/// or as a single $List, e.g.:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, $ListBuild("a", "b", "c", ...))
/// or as JSON, to use as keyword parameters:
///   Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, {"a":42})
ClassMethod TemplateReplace(Template As %String, Parameters... As %String) As %String
{
	;Allow passing in a $list with parameters
	If $Get(Parameters) = 1, $Get(Parameters(1)) '= "", $ListValid(Parameters(1)) {
		Set Data = Parameters(1)
		Set Parameters = $ListLength(Data)
		For i = 1:1:$ListLength(Data) Set Parameters(i) = $ListGet(Data, i)
		
	} Else {
		; Allow keyword arguments by passing in a JSON literal
		For i = 1:1:$Get(Parameters) {
			If '$IsObject($Get(Parameters(i))) Continue
			If 'Parameters(i).%IsA("%Library.DynamicObject") Continue
			; Dynamic object; create array for easy access and possibly merging
			Set it = Parameters(i).%GetIterator()
			While it.%GetNext(.key, .value) { Set kwa(key) = value }
			Kill Parameters(i)
		}
		
	}
	
	Set RefCounter = 0
	Set Index = ""
	For  {
		Set Index = $Find(Template, "{", Index)
		If Index = 0 Quit
		
		;Found a brace -- check if the next char is a brace as well
		If $Extract(Template, Index) = "{" {
			;Two braces; the first escapes the second
			Set $Extract(Template, Index) = ""
			Continue
		}
		
		;Found the start of a replacement definition; remember this location
		Set StartIndex = Index - 1
		
		;Find terminating brace
		Set Index = $Find(Template, "}", Index)
		If Index = 0 Quit
		
		;Found terminating brace; remember its position
		Set EndIndex = Index - 1
		
		;Increment auto parameter reference counter
		Set RefCounter = RefCounter + 1
		
		;Determine parameter number
		If EndIndex - StartIndex = 1 {
			;Special case: {} means "use the next one"
			Set ParmNumber = RefCounter
			
		} Else {
			Set ParmNumber = $Extract(Template, StartIndex + 1, EndIndex - 1)
			
		}
		
		If ParmNumber ? 1.N {
			;Get parameter value
			Set Value = $Get(Parameters(ParmNumber))
			
		} Else {
			; Possible keyword argument passed as json
			Set Value = $Get(kwa(ParmNumber))
			
		}
		Set ValueLen = $Length(Value)
		
		;Replace parameter reference with actual value
		Set $Extract(Template, StartIndex, EndIndex) = Value
		
		;Correct index for difference in length between parm reference and its substituted value
		Set Index = Index - (EndIndex - StartIndex) - ValueLen - 1
	}
	
	Quit Template
}

/// Converts a binary sequence of bytes into a string of hexadecimal digits
/// representing the byte's value.
ClassMethod HexEncode(Input As %Binary, Lowercase As %Boolean = 1) As %String
{
	Set Result = ""
	
	For i = 1:1:$Length(Input) {
		Set Byte = $Extract(Input, i)
		Set Hex = $ZHex($Ascii(Byte))
		If $Length(Hex) = 1 Set Hex = "0"_Hex
		Set Result = Result_Hex
	}
	
	If Lowercase Set Result = $ZConvert(Result, "l")
	
	Quit Result
}

/// Converts a %ListOfDataType-type object to a character-separated
/// string if Separator is non-empty, or to a %List if it is empty.
ClassMethod ListObjToString(List As %Collection.AbstractListOfDT, Separator As %String = ",") As %String
{
	Set Result = ""
	
	Set Key = "", Nr = 0
	For  {
		Set Value = List.GetNext(.Key)
		If Key = "" Quit
		Set Nr = Nr + 1
		
		If Separator '= "" {
			If Nr > 1 Set Result = Result_Separator
			Set Result = Result_Value
		} Else {
			Set Result = Result_$ListBuild(Value)
		}
	}
	
	Quit Result
}

/// Converts a character-separated string or a %List into a
/// %ListOfDataType-type object. If no list object is passed in,
/// a %ListOfDataTypes object is created.
ClassMethod ListObjFromString(Input As %String, Separator As %String = ",", Output Result As %Collection.AbstractListOfDT)
{
	If '$IsObject($Get(Result)) Set Result = ##class(%ListOfDataTypes).%New()
	
	If Input = "" Quit
	
	If $ListValid(Input) {
		For i = 1:1:$ListLength(Input) {
			Do Result.Insert($ListGet(Input, i))
		}
		
	} Else {
		For i = 1:1:$Length(Input, Separator) {
			Do Result.Insert($Piece(Input, Separator, i))
		}
	}
	
	Quit
}

/// Replace based on a regular expression. Example:
///   . RxReplace("XnXValue", "^XnX(.*)", "$1") = "Value"
ClassMethod RxReplace(String As %String, RegEx As %String, With As %String) As %String
{
	Set rx = ##class(%Regex.Matcher).%New(RegEx, String)
	Set Result = rx.ReplaceAll(With)
	Quit Result
}

/// Returns a quoted string unquoted ("XXX" becomes XXX).
ClassMethod UnQuote(Input As %String, Unescape As %Boolean = 0) As %String
{
	If $Extract(Input) '= """" Quit Input
	If $Extract(Input, *) '= """" Quit Input
	Set Input = $Extract(Input, 2, *-1)
	If Unescape Set Input = $Replace(Input, """""", """")
	Quit Input
}

/// Removes an entry from a (by default) comma-separated list.
/// Returns the new list with the entry removed, or the unaltered
/// input if LookFor is not found. Outputs whether is was in Found.
ClassMethod RemoveFromList(Input As %String, Sep As %String = ",", LookFor As %String, Output Found As %Boolean) As %String
{
	Set Found = 0
	If Input = "" Quit ""
	Set List = $ListFromString(Input, Sep)
	Set Index = $ListFind(List, LookFor)
	If 'Index Quit Input
	
	Set $List(List, Index, Index) = ""
	Set Found = 1
	Quit $ListToString(List, Sep)
}

}
