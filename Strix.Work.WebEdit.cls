<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Work.WebEdit">
<Description>
Simple class to make editing of persistent classes through CSP possible.
To use, create a subclass and specify at least parameter ClassName.</Description>
<Abstract>1</Abstract>
<IncludeCode>Strix</IncludeCode>
<IncludeGenerator>Strix</IncludeGenerator>
<Super>%CSP.Page</Super>
<TimeCreated>65140,44787.654621</TimeCreated>

<Parameter name="ClassName">
<Description>
The name of the class to edit instances of.</Description>
<Type>CLASSNAME</Type>
</Parameter>

<Parameter name="ListFields">
<Description>
The fields to use for listing, separated by commas. Default is to use
all fields. Can be either positive (fields to use) or negative (fields
to exclude); in the latter case, prefix the field name with a minus (-).</Description>
<Type>STRING</Type>
</Parameter>

<Parameter name="FieldTypes">
<Description>
HTML type overrides to use for fields. Contains a comma-separated list
of specifications of the form:
  PropertyName:HTMLWidget:Attr=Value:Attr=Value:...
PropertyName is the name of the property to specify the widget for
HTMLWidget is "text" (default) or "textarea"
Attr=Value specifies (optional) attributes for the widget, e.g. "cols=50".</Description>
<Type>STRING</Type>
</Parameter>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="OnPreHTTP">
<ClassMethod>1</ClassMethod>
<PublicList>msg,emsg</PublicList>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
	Set (msg, emsg) = ""
	
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	Set ClassName = ..ClassName()
	
	; Message may have arrived from previous page after redirect
	Set msg = %request.GetCookie("Msg")
	If msg '= "" Do %response.SetCookie("Msg", "")
	
	; Actions below should only be done with a post request
	If %request.Method '= "POST" Quit 1
	
	Set Action = %request.Get("action")
	If Action = "" Quit 1
	
	Set Id = %request.Get("id")
	If Action = "delete" {
		If Id = "" || '$ZObjClassMethod(ClassName, "%ExistsId", Id) Set emsg = "Error: no id." Quit 1
		Set sc = $ZObjClassMethod(ClassName, "%DeleteId", Id)
		If 'sc Set emsg = ..ErrMsg("Error deleting object:", sc) Quit 1
		Set %response.Redirect = ..%ClassName(1)_".cls"
		Do %response.SetCookie("Msg", ..ClassName(0)_" object with id "_Id_" deleted.")
	}
	
	If Action = "save" {
		If Id '= "", '$ZObjClassMethod(ClassName, "%ExistsId", Id) Set emsg = "Error: no id." Quit 1
		Set emsg = ..SaveObject(Id) If emsg '= "" Quit 1
		Set %response.Redirect = ..%ClassName(1)_".cls"
		Do %response.SetCookie("Msg", ..ClassName(0)_" object with id "_Id_" saved.")
	}
	
	
	
	Quit 1
]]></Implementation>
</Method>

<Method name="OnPage">
<ClassMethod>1</ClassMethod>
<PublicList>msg,emsg</PublicList>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Set $ZTrap = "Error"
	
	; Error message: show in special page
	If emsg '= "" Quit ..ErrorPage(emsg)
	
	; Check requested action
	Set Action = %request.Get("action")
	If Action = "" {
		Quit ..List(msg)
		
	} ElseIf Action = "edit" {
		Quit ..Edit(msg)
		
	}
	
	Quit ..ErrorPage("Internal error: unrecognised action.")
	
	
Error
	Set $ZTrap = ""
	Write ..ErrMsg("Error trapped:", , 1, $Char(13,10), 0, 1)
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="List">
<ClassMethod>1</ClassMethod>
<FormalSpec>Message:%String=""</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Do ..Header("List "_..ClassName(0), , Message)
	
	&html<
<script type="text/javascript">
function ays(cls,id)
{
	return confirm("Are you sure you want to delete the '"+cls+"' object with id '"+id+"'?")
}
</script>>
	
	Set PropList = ..GetProperties()
	If PropList = "" Quit $$$OK
	
	Set ListFields = ..GetListFields()
	
	Set qs = ##class(%SQL.Statement).%New()
	Set sc = qs.%PrepareClassQuery(..ClassName(1), "Extent")
	If 'sc Quit $$$BuildStatus("Error preparing extent query:", sc)
	#dim rs As %SQL.StatementResult
	Set rs = qs.%Execute()
	
	; Header
	&html<<table id=oblist>>
	&html<<tr><th><a class="far fa-plus-square" href="?action=edit"></a></th>>
	For i = 1:1:$ll(PropList) {
		Set PropInfo = $List(PropList, i)
		Set Name = $List(PropInfo, 1)
		If ListFields '= "", '$ListFind(ListFields, Name) Continue
		&html<  <th>#(Name)#</th>>
	}
	&html<</tr>>
	
	; Objects
	Set ClassName = ..ClassName()
	While rs.%Next() {
		Set Id = rs.%Get("ID")
		Set o = $ZObjClassMethod(ClassName, "%OpenId", Id, , .sc)
		If 'sc Return sc
		
		&html<<tr>
  <td>
    <a class="far fa-edit" href="?action=edit&id=#(Id)#"></a>
    <form style="display:inline" method=post action="?action=delete&id=#(Id)#" onsubmit="return ays('#(..ClassName(0))#','#(Id)#')">
    <button type=submit class="far fa-trash-alt"></button></form>
  </td>>
		For i = 1:1:$ll(PropList) {
			Set PropInfo = $List(PropList, i)
			Set Name = $List(PropInfo, 1), Type = $List(PropInfo, 2)
			If ListFields '= "", '$ListFind(ListFields, Name) Continue
			
			Set Value = $ZObjProperty(o, Name)
			If Value '= "" {
				If Type = "%Date" {
					Set Value = $ZDate(Value, 3)
				} ElseIf Type = "%TimeStamp" {
					;leave as-is
				}
			}
			&html<  <td>#($ZConvert(Value, "O", "HTML"))#</td>>
		}
		&html<</tr>>
	}
	
	&html<</table>>
	
	Do ..Footer()
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="Edit">
<ClassMethod>1</ClassMethod>
<FormalSpec>Message:%String=""</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Set Id = %request.Get("id")
	
	Set ClassName = ..ClassName()
	If Id '= "" {
		Set Object = $ZObjClassMethod(ClassName, "%OpenId", Id, , .sc)
		If 'sc Quit ..ErrorPage("Error opening object.", sc)
		Set Header = "Edit "_..ClassName(0)_" object with id '"_Id_"'"
	} Else {
		Set Object = $ZObjClassMethod(ClassName, "%New")
		Set Header = "Edit new "_..ClassName(0)_" object"
	}
	
	Do ..Header(Header, , Message)
	
	Set PropList = ..GetProperties()
	Do ..GetFieldTypes(.Types)
	
	&html<<form method=post action="#(..%ClassName(1))#.cls">>
	&html<<table id=object>>
	
	For i = 1:1:$ListLength(PropList) {
		Set PropInfo = $List(PropList, i)
		Set Name = $List(PropInfo, 1)
		Set FieldSpec = $Get(Types(Name))
		
		&html<<tr>>
		&html<  <th>#(Name)#</th>>
		&html<  <td>>
		&html<#(..FieldEdit(Object, PropInfo, FieldSpec))#>
		&html<</td>>
		&html<</tr>>
	}
	
	&html<</table>>
	
	&html<<div class=btnrow>>
	&html<<button type=submit name=action value=save><span class="far fa-save"></span> Save</button>>
	&html<<a class="far fa-list-alt button" href="?"> List</a>>
	
	&html<</div>>
	
	&html<<input type=hidden name=id value="#(Id)#">>
	&html<</form>>
	
	
	Do ..Footer()
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="FieldEdit">
<ClassMethod>1</ClassMethod>
<FormalSpec>Object:%Persistent,PropInfo:%List,FieldSpec:%List</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Name = $List(PropInfo, 1), Type = $List(PropInfo, 2)
	
	; html type
	Set HtmlType = $ListGet(FieldSpec, 1)
	If HtmlType = "" Set HtmlType = "text"
	
	Set Attrs = $ListGet(FieldSpec, 2)
	Set AttrString = ""
	For i = 1:1:$ListLength(Attrs) {
		Set Item = $List(Attrs, i), AttrName=$List(Item, 1), AttrValue = $List(Item, 2)
		If AttrString '= "" Set AttrString = AttrString_" "
		Set AttrString = AttrString_AttrName_"="""_..EscapeHTML(AttrValue)_""""
	}
	
	Set Value = $ZObjProperty(Object, Name)
	
	If Value '= "" {
		If Type = "%Date" Set Value = $ZDate(Value, 3)
	}
	
	If HtmlType = "text" {
		&html<<input type=text name="#(Name)#" value="#(..EscapeHTML(Value))#" #(AttrString)#>>
		
	} ElseIf HtmlType = "textarea" {
		&html<<textarea name="#(Name)#" #(AttrString)#>#(..EscapeHTML(Value))#</textarea>>
		
	} Else {
		Write "Unknown edit type "_HtmlType_"."
	}
	
	
	Quit ""
]]></Implementation>
</Method>

<Method name="ErrorPage">
<ClassMethod>1</ClassMethod>
<FormalSpec>Msg:%String,Title:%String="An error has occurred."</FormalSpec>
<Implementation><![CDATA[
	Do ..Header(Title, "error")
	
	&html<<div class=error>#(Msg)#</div>>
	
	Do ..Footer()
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="Header">
<ClassMethod>1</ClassMethod>
<FormalSpec>Title:%String="",Class:%String="",Message:%String=""</FormalSpec>
<Implementation><![CDATA[
	&html<<!DOCTYPE HTML>
<html>
<head>
<title>#(..EscapeHTML(Title))#</title>
#(..CSS())#
</head>
<body #($s(Class'="":" class='"_Class_"'", 1: ""))#>
<h1>#(..EscapeHTML(Title))#</h1>>
	
	; Show message; a click on the span removes it.
	If Message '= "" {
		&html<<div class="msg"><span class="fas fa-check" onclick="el=this.parentNode;el.parentNode.removeChild(el);"></span> #(..EscapeHTML(Message))#</div>>
	}
	
	Quit ""
]]></Implementation>
</Method>

<Method name="Footer">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	&html<</body>
</html>>
]]></Implementation>
</Method>

<Method name="ErrMsg">
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

<Method name="CSS">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	&html<
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.1/css/all.css" integrity="sha384-50oBUHEmvpQ+1lW4y57PTFmhCaXp0ML5d60M1M7uH2+nqUivzIebhndOJK28anvf" crossorigin="anonymous">
<style>
html {
  box-sizing: border-box;
  font-family: Arial, sans-serif;
  height: 100%;
  padding: 0;
  margin: 0
}

body {
  box-sizing: border-box;
  background-color: c2a080;
  padding: 0 1em 2em 1em;
  margin: 0;
  min-height: 100%;
}

h1 {
  font-family: "Trebuchet MS", Arial, sans-serif;
  background-color: teal;
  color: #ccc;
  margin: 0 -1em 1em -1em;
  padding: 0.2em 1em;
  font-size: 1.8em;
}
.error h1 {
  background-color: red;
  color: yellow;
}

th {
  font-weight: normal;
  text-align: left;
}

#oblist {
  border: 1px solid #ccc;
  border-collapse: collapse;
}
#oblist th, #oblist td {
  border: 1px solid #ccc;
}
#oblist th {
  background-color: #069;
  color: white;
  padding: 0.15em 0.5em;
}
#oblist tr:first-child th:first-child {
  background-color: #fafcff;
}
#oblist td {
  padding: 0 0.5em;
}

a.far {
  line-height: 1.5em;
  color: blue;
  text-decoration: none;
}
button.far {
  color: blue;
  cursor: pointer;
  border: none;
  padding: none;
  background-color: transparent;
}
button, a.button {
  font-size: 105%;
  line-height: 1.2;
  background-color: #f0efec;
  margin: 0 0.3em;
  padding: 0.3em 0.5em;
  border: 1px solid #aaa;
  color: black;
  cursor: pointer;
}

.btnrow {
  margin: 1em 0.5em 1em 0;
}
input[type=text]:not([size]) {
  width: 30em;
}
textarea {
  font-size: 110%;
}

div.msg {
  border: 3px double #696;
  border-radius: 5px;
  background-color: #fffcfc;
  padding: 0.5em;
  margin: 0 0 1em 0;
}
div.msg .fa-check {
  color: green;
}


</style>>
	Quit ""
]]></Implementation>
</Method>

<Method name="GetListFields">
<Description>
Return a list of property names to display in the list page</Description>
<ClassMethod>1</ClassMethod>
<ReturnType>%List</ReturnType>
<Implementation><![CDATA[
	; Get specification from parameter
	Set Spec = $Translate(..#ListFields, " ")
	
	If $Extract(Spec) = "-" || (Spec = "") {
		Set Spec = $Translate(Spec, "-")
		Set Spec = $ListFromString(Spec)
		
		; Get list of all names, and exclude those in spec
		Set Temp = ..GetProperties(), ListFields = ""
		For i = 1:1:$ListLength(Temp) {
			Set Name = $List($List(Temp, i), 1)
			If $ListFind(Spec, Name) Continue
			Set ListFields = ListFields_$ListBuild(Name)
		}
		
	} Else {
		Set ListFields = $ListFromString(Spec)
		
	}
	
	Quit ListFields
]]></Implementation>
</Method>

<Method name="GetFieldTypes">
<ClassMethod>1</ClassMethod>
<FormalSpec>*Types</FormalSpec>
<Implementation><![CDATA[
	Set Spec = ..#FieldTypes
	If Spec = "" Quit ""
	
	For i = 1:1:$Length(Spec, ",") {
		Set Item = $Piece(Spec, ",", i)
		
		Set Name = $Piece(Item, ":", 1)
		Set Type = $Piece(Item, ":", 2)
		
		Set Attrs = ""
		For j = 3:1:$Length(Item, ":") {
			Set AttrSpec = $Piece(Item, ":", j)
			Set AttrName = $Piece(AttrSpec, "=", 1), AttrValue = $Piece(AttrSpec, "=", 2)
			Set Attrs = Attrs_$ListBuild($ListBuild(AttrName, AttrValue))
		}
		Set Types(Name) = $ListBuild(Type, Attrs)
	}
	
	Quit
]]></Implementation>
</Method>

<Method name="SaveObject">
<ClassMethod>1</ClassMethod>
<FormalSpec>Id:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	
	If Id '= "" {
		Set Obj = $ZObjClassMethod(..ClassName(), "%OpenId", Id, , .sc)
		If 'sc Quit ..ErrMsg("Error opening object:", sc)
	} Else {
		Set Obj = $ZObjClassMethod(..ClassName(), "%New")
	}	
	
	Set PropList = ..GetProperties()
	For i = 1:1:$ListLength(PropList) {
		Set PropInfo = $List(PropList, i)
		Set Name = $List(PropInfo, 1), Type = $List(PropInfo, 2)
		
		Set Value = $ZStrip(%request.Get(Name), ">W")
		
		If Type = "%String" || (Type = "%TimeStamp") || (Value = "") {
			Set $ZObjProperty(Obj, Name) = Value
			
		} ElseIf Type = "%Date" {
			Set Logical = $ZDateH(Value, 3,,,,,,,"error")
			If Logical = "error" Return ..ErrMsg($$$BuildStr("Invalid value for {}: {}.", Name, Value))
			Set $ZObjProperty(Obj, Name) = Logical
			
		} Else {
			
		}
	}
	Set sc = Obj.%Save()
	If 'sc Quit ..ErrMsg("Error saving object:", sc)
	
	Quit ""
]]></Implementation>
</Method>

<Method name="GetProperties">
<ClassMethod>1</ClassMethod>
<CodeMode>objectgenerator</CodeMode>
<ReturnType>%List</ReturnType>
<Implementation><![CDATA[
	If %class.Abstract Quit $$$OK
	If %parameter("ClassName") = "" Quit $$$BuildStatus("Parameter ClassName required.")
	
	Set Dic = ##class(%Dictionary.CompiledClass).%OpenId(%parameter("ClassName"), , .sc)
	If 'sc Quit $$$BuildStatus("Error opening class definition for class {}:", sc, %parameter("ClassName"))
	
	#dim Properties As %Collection.AbstractList
	Set Properties = ##class(Strix.Generator.Utilities).GetOrderedList(Dic.Properties, .sc)
	If 'sc Quit $$$BuildStatus("Error retrieving property list for {}:", sc, ..ClassName(1))
	
	Set ListText = ""
	
	For i = 1:1:Properties.Count() {
		#dim Prop As %Dictionary.CompiledProperty
		Set Prop = Properties.GetAt(i)
		If Prop.Calculated Continue
		If Prop.Internal Continue
		If Prop.MultiDimensional Continue
		If Prop.Transient Continue
		
		Set Name = Prop.Name
		If $Extract(Name) = "%" Continue
		
		Set Type = Prop.Type
		If '$$$classIsDataType($$$NormalizeClassname(Type)) Continue
		
		Set Type = $$$DenormalizeClassname(Type)
		
		If '$lf($lfs("%String,%Date,%TimeStamp"), Type) {
			Write !,"Warning: don't know how to handle type "_Type_", skipping."
			Continue
		}
		
		
		If ListText '= "" Set ListText = ListText_","
		Set ListText = ListText_"$lb("""_Name_""","""_Type_""")"
		
		
	}
	
	Do %code.WriteLine($Select(ListText '= "": " Quit $lb("_ListText_")", 1: " Quit """""))
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ClassName">
<Description>
Returns the classname of the edited class</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Full:%Boolean=1</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set ClassName = ..#ClassName
	If 'Full Quit $Piece(ClassName, ".", *)
	Quit ClassName
]]></Implementation>
</Method>
</Class>
</Export>
