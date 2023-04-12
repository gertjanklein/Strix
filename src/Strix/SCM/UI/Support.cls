Class Strix.SCM.UI.Support Extends %CSP.Page
{

ClassMethod DecomposeStatus(Message As %String = "", Status As %Status = "", EscapeHTML = 1, Separator As %String = "<br>", Nl2Br = 1, AddZE As %Boolean = 0)
{
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
}

ClassMethod TextInput(Name As %String, Size As %Integer) As %String
{
	Set Result = "<input type=""text"" name="""_Name_""""
	
	Set Result = Result_" class=""Text"""
	
	If $Get(Size) Set Result = Result_" size="""_Size_""""
	
	Set Value = %request.Get(Name)
	If Value '= "" Set Result = Result_" value="""_..EscapeHTML(Value)_""""
	
	Set Result = Result_">"
	
	Quit Result
}

ClassMethod TextArea(Name As %String, Rows As %Integer, Cols As %Integer) As %String
{
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
}

ClassMethod HiddenInput(Name As %String) As %String
{
	Set Result = "<input type=""hidden"" name="""_Name_""""
	
	Set Value = %request.Get(Name)
	If Value '= "" Set Result = Result_" value="""_..EscapeHTML(Value)_""""
	
	Set Result = Result_">"
	
	Quit Result
}

ClassMethod CheckBox(Name As %String, ForceChecked As %Boolean = 0) As %String
{
	Set Result = "<input type=""checkbox"" name="""_Name_""" value=1"
	
	If %request.Get(Name, 0) || ForceChecked Set Result = Result_" checked"
	
	Set Result = Result_">"
	
	Quit Result
}

}
