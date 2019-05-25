<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.SCM.UI.Support">
<Super>%CSP.Page</Super>
<TimeCreated>64293,67266.95157</TimeCreated>

<Method name="DecomposeStatus">
<ClassMethod>1</ClassMethod>
<FormalSpec><![CDATA[Message:%String="",Status:%Status="",EscapeHTML=1,Separator:%String="<br>",Nl2Br=1,AddZE:%Boolean=0]]></FormalSpec>
<Implementation><![CDATA[
	If EscapeHTML Set Message = ..EscapeHTML(Message)
	
	If Status '= "" {
		Set s = ""
		Do $System.Status.DecomposeStatus(Status, .ErrorList)
		For i = 1:1:ErrorList {
			If i > 1 Set s = s_Separator
			If EscapeHTML {
				Set s = s_$ZConvert(ErrorList(i), "O", "HTML")
			} Else {
				Set s = s_ErrorList(i)
			}
		}
		If $Extract(Message, $Length(Message)) '= ":" Set Message = Message_":"
		Set Message = Message_Separator_s
	}
	
	If Nl2Br, $Length(Message, $Char(10)) {
		Set Result = ""
		For i = 1:1:$Length(Message, $Char(10)) {
			If i > 1 Set Result = Result_$Char(10)_"<br>"
			Set Result = Result_$Piece(Message, $Char(10), i)
		}
		Set Message = Result
	}
	
	If AddZE Set Message = Message_Separator_$Select(EscapeHTML: $ZConvert($ZError, "O", "HTML"), 1: $ZError)
	
	Quit Message
]]></Implementation>
</Method>

<Method name="TextInput">
<ClassMethod>1</ClassMethod>
<FormalSpec>Name:%String,Size:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = "<input type=""text"" name="""_Name_""""
	
	Set Result = Result_" class=""Text"""
	
	If $Get(Size) Set Result = Result_" size="""_Size_""""
	
	Set Value = %request.Get(Name)
	If Value '= "" Set Result = Result_" value="""_..EscapeHTML(Value)_""""
	
	Set Result = Result_">"
	
	Quit Result
]]></Implementation>
</Method>

<Method name="TextArea">
<ClassMethod>1</ClassMethod>
<FormalSpec>Name:%String,Rows:%Integer,Cols:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Value = %request.Get(Name)
	
	;Simple auto-resize
	Set Lines = $Length(Value, $Char(10))
	If Lines > Rows Set Rows = Lines
	
	Set Result = "<textarea name="""_Name_""""
	Set Result = Result_" rows="""_Rows_""" cols="""_Cols_""">"
	
	Set Value = %request.Get(Name)
	If Value '= "" Set Result = Result_..EscapeHTML(Value)
	
	Set Result = Result_"</textarea>"
	
	Quit Result
]]></Implementation>
</Method>

<Method name="HiddenInput">
<ClassMethod>1</ClassMethod>
<FormalSpec>Name:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = "<input type=""hidden"" name="""_Name_""""
	
	Set Value = %request.Get(Name)
	If Value '= "" Set Result = Result_" value="""_..EscapeHTML(Value)_""""
	
	Set Result = Result_">"
	
	Quit Result
]]></Implementation>
</Method>

<Method name="CheckBox">
<ClassMethod>1</ClassMethod>
<FormalSpec>Name:%String,ForceChecked:%Boolean=0</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = "<input type=""checkbox"" name="""_Name_""""
	
	If %request.IsDefined(Name) || ForceChecked Set Result = Result_" checked"
	
	Set Result = Result_">"
	
	Quit Result
]]></Implementation>
</Method>
</Class>
</Export>
