<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.String">
<Description>
Various string manipulation methods.</Description>
<Super>%RegisteredObject</Super>
<TimeCreated>63850,48932.807424</TimeCreated>

<Method name="Explode">
<Description>
Converts a piece-separated string to individual pieces, indexed sequentially.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Input:%String,Separator:%String,*Pieces:%String</FormalSpec>
<Implementation><![CDATA[
	Kill Pieces
	Set Pieces = 0
	
	If Input = "" Quit
	
	For i = 1:1:$Length(Input, Separator) {
		Set Pieces($Increment(Pieces)) = $Piece(Input, Separator, i)
	}
	
	Quit
]]></Implementation>
</Method>

<Method name="ListFromArray">
<Description>
Converts the keys of an array to a %List or (if Separator is not empty)
a piece-separated string.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec><![CDATA[&Array:%String,Separator:%String=","]]></FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = ""
	Set Key = ""
	For  {
		Set Key = $Order(Array(Key))
		If Key = "" Quit
		Set Result = Result_$ListBuild(Key)
	}
	
	If Separator '= "" Set Result = $ListToString(Result, Separator)
	
	Quit Result
]]></Implementation>
</Method>

<Method name="SplitLines">
<Description>
Splits a string containing newlines into a list of lines. StripCfg
configures how whitespace in the lines is handled; if empty it is left
untouched.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec><![CDATA[Input:%String,StripCfg:%String=">WC",SkipEmptyLines:%Boolean=0]]></FormalSpec>
<ReturnType>%ListOfDataTypes</ReturnType>
<Implementation><![CDATA[
	Set Result = ##class(%ListOfDataTypes).%New()
	For i = 1:1:$Length(Input, $Char(10)) {
		Set Line = $Piece(Input, $Char(10), i)
		If StripCfg '= "" Set Line = $ZStrip(Line, StripCfg)
		If SkipEmptyLines, Line = "" Continue
		Do Result.Insert(Line)
	}
	Quit Result
]]></Implementation>
</Method>

<Method name="TemplateReplace">
<Description>
Replaces parameter references in property Text with their values in property Parameters.

Parameter references use braces, as in:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {1}{2}{3}", "a", "b", "c")
The number between the braces is the parameter number, and is optional if
this number would equal the parameter reference number. The following example
therefore gives the same result as the previous one:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {1}{}{3}", "a", "b", "c")
and this example as well:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace("abc = {}{}{}", "a", "b", "c")

Values may be passed in as multiple method parameters, e.g.:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, "a", "b", "c", ...)
or as a single $List, e.g.:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, $ListBuild("a", "b", "c", ...))
or as JSON, to use as keyword parameters:
  Set Result  = ##class(Strix.Lib.String).TemplateReplace(Text, {"a":42})</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Template:%String,Parameters...:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="HexEncode">
<Description>
Converts a binary sequence of bytes into a string of hexadecimal digits
representing the byte's value.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Input:%Binary,Lowercase:%Boolean=1</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = ""
	
	For i = 1:1:$Length(Input) {
		Set Byte = $Extract(Input, i)
		Set Hex = $ZHex($Ascii(Byte))
		If $Length(Hex) = 1 Set Hex = "0"_Hex
		Set Result = Result_Hex
	}
	
	If Lowercase Set Result = $ZConvert(Result, "l")
	
	Quit Result
]]></Implementation>
</Method>

<Method name="ListObjToString">
<Description>
Converts a %ListOfDataType-type object to a character-separated
string if Separator is non-empty, or to a %List if it is empty.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>List:%Collection.AbstractListOfDT,Separator:%String=","</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="ListObjFromString">
<Description>
Converts a character-separated string or a %List into a
%ListOfDataType-type object. If no list object is passed in,
a %ListOfDataTypes object is created.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Input:%String,Separator:%String=",",*Result:%Collection.AbstractListOfDT</FormalSpec>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="RxReplace">
<Description>
Replace based on a regular expression. Example:
  . RxReplace("XnXValue", "^XnX(.*)", "$1") = "Value"</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>String:%String,RegEx:%String,With:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set rx = ##class(%Regex.Matcher).%New(RegEx, String)
	Set Result = rx.ReplaceAll(With)
	Quit Result
]]></Implementation>
</Method>

<Method name="UnQuote">
<Description>
Returns a quoted string unquoted ("XXX" becomes XXX).</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Input:%String,Unescape:%Boolean=0</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	If $Extract(Input) '= """" Quit Input
	If $Extract(Input, *) '= """" Quit Input
	Set Input = $Extract(Input, 2, *-1)
	If Unescape Set Input = $Replace(Input, """""", """")
	Quit Input
]]></Implementation>
</Method>
</Class>
</Export>
