Include %occErrors

Class Strix.Lib.Depends Extends %RegisteredObject
{

Property Checked As %String [ MultiDimensional ];

Property Dependencies As %String [ MultiDimensional ];

Property Warn As %Boolean [ InitialExpression = 1 ];

/// Cached regex objects (performance)
Property Matchers As array Of %Regex.Matcher;

// =====

/// Terminal helper to find dependencies of one or more items.
/// Specify with type suffix (xx.cls, xx.pkg, ...).
/// Do ##class(Strix.Lib.Depends).Check("...")
ClassMethod Check(Items As %String)
{
	Set Me = ..%New()
	
	; Search for dependencies:
	For i = 1:1:$Length(Items, ",") {
		Set Item = $Piece(Items, ",", i)
		
		If $ZConvert($Piece(Item, ".", *), "l") = "pkg" {
			Set Item = $Piece(Item, ".", 1, *-1)
			Set sc = Me.CheckPackage(Item)
			
		} Else {
			Set sc = Me.CheckItem(Item)
			
		}
		If 'sc {
			Write ..BuildMsg("Error checking dependencies for {}:", sc, Item),!
			Return
		}
	}
	
	; Display
	Write "Dependencies detected:",!
	Set Name = ""
	For  {
		Set Name = $Order(Me.Dependencies(Name))
		If Name = "" Quit
		Write Name,!
	}
	
	Return
}

// =====

/// Check all dependencies of one or more packages.
Method CheckPackage(Packages As %String) As %Status
{
	For i = 1:1:$Length(Packages, ",") {
		Set Package = $Piece(Packages, ",", i)
		
		Kill Items
		Set sc = $System.OBJ.GetPackageList(.Items, Package)
		If 'sc Return ..BuildStatus("Error determining package list for '{}':", sc, Package)
		
		Set Item = ""
		For  {
			Set Item = $Order(Items(Item))
			If Item= "" Quit
			
			Set sc = ..CheckItem(Item_".cls")
			If 'sc Return ..BuildStatus("Error checking '{}':", sc, Item)
		}
	}
	
	Quit $$$OK
}

/// Checks dependencies for a single item. Item should end with
/// it's type (e.g. '.cls', '.inc', ...)
Method CheckItem(Item As %String, Source As %String = "") As %Status
{
	; Make sure we know what to do with Item
	Set Types = $ListFromString("cls,mac,inc")
	Set Type = $ZConvert($Piece(Item, ".", *), "l")
	If '$ListFind(Types, Type) {
		Quit ..BuildStatus("Error: unsupported type '{}' (known types are {}).",
		  , Type, $ListToString(Types))
	}
	
	; If we've seen this one before, quit here
	If '..AddItem(Item, Source) Quit $$$OK
	
	If Type = "cls" {
		Set sc = ..CheckClassDeps($Piece(Item, ".", 1, *-1))
		If 'sc Quit sc
		
	} ElseIf Type = "inc" {
		Set Inc = ##class(%Routine).%OpenId(Item, , .sc)
		If 'sc Quit sc
		Set sc = ..CheckCode(Inc, , Item)
		
	}
	
	Quit $$$OK
}

/// Checks a single class for its dependencies. Name should not
/// include the '.cls' type.
Method CheckClassDeps(ClassName As %String) As %Status [ Private ]
{
	; Start with what this returns:
	Set sc = $System.OBJ.GetDependencies(ClassName, .Items, "")
	If 'sc Quit ..BuildStatus("Error from system for class {}:", sc, ClassName)
	
	Set Item = ""
	For  {
		Set Item = $Order(Items(Item))
		If Item = "" Quit
		Set Name = Item_".cls"
		If '$Data(..Checked(Name)) Do ..CheckItem(Name, ClassName)
	}
	
	
	Set Def = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .sc)
	If 'sc Quit ..BuildStatus("Error opening definition for class {}:", sc, ClassName)
	
	#define AddCsv(%t,%l) If %l '="" {For i = 1:1:$l(%l,",") Set n=$p(%l,",",i)_%t i $e(n)'="%",'$d(..Checked(n)) s sc=..CheckItem(n, ClassName) i 'sc return sc}
	
	$$$AddCsv(".cls",Def.CompileAfter)
	$$$AddCsv(".cls",Def.ConstraintClass)
	$$$AddCsv(".cls",Def.DependsOn)
	$$$AddCsv(".cls",Def.EmbeddedClass)
	$$$AddCsv(".cls",Def.IndexClass)
	$$$AddCsv(".cls",Def.MemberSuper)
	$$$AddCsv(".cls",Def.ProjectionClass)
	$$$AddCsv(".cls",Def.PropertyClass)
	$$$AddCsv(".cls",Def.QueryClass)
	$$$AddCsv(".cls",Def.Super)
	$$$AddCsv(".cls",Def.TriggerClass)
	
	$$$AddCsv(".inc",Def.IncludeCode)
	$$$AddCsv(".inc",Def.IncludeGenerator)
	
	Set Package = $Piece(ClassName, ".", 1, *-1)
	
	Set key = ""
	For  {
		#dim md As %Dictionary.MethodDefinition
		Set md = Def.Methods.GetNext(.key)
		If key = "" Quit
		
		Set sc = ..CheckCode(md.Implementation, Package, ClassName)
		If 'sc Return ..BuildStatus("Error checking method {}:", sc, md.Name)
	}
	
	
	;Projections, ...
	
	Quit $$$OK
}

/// Checks code, passed as a stream, for references to classes.
Method CheckCode(Code As %Stream, Package As %String = "User", Source = "") As %Status
{
	; Check for classmethod calls and #dim statements
	Set RegExes = $lb("##class\(([^)%]+)\)", "(?i)#dim +\w+ +As +([\w.]+)")
	
	While 'Code.AtEnd {
		Set Line = Code.ReadLine()
		If $ZStrip(Line, "<>W") = "" Continue
		
		For i = 1:1:$ll(RegExes) {
			; Get cached matcher, if already present
			Set RegEx = $li(RegExes, i)
			If ..Matchers.IsDefined(RegEx) {
				Set Matcher = ..Matchers.GetAt(RegEx)
			} Else {
				; Create matcher for this regex and add to cache
				Set Matcher = ##class(%Regex.Matcher).%New(RegEx)
				Do ..Matchers.SetAt(Matcher, RegEx)
			}
			
			; Attempt to match the current code line
			Set Matcher.Text = Line
			While Matcher.Locate() {
				Set Item = Matcher.Group(1)
				If Item '[ "." Set Item = Package_"."_Item
				Set Item = Item_".cls"
				If $Data(..Checked(Item)) Continue
				Set sc = ..CheckItem(Item, Source)
				If 'sc Return sc
			}
		}
	}
	
	Quit $$$OK
}

// =====

/// Adds an item to the dependency array, after checking that
/// it is not a system item, and making sure it exists. Returns
/// a boolean indicating whether further processing is needed.
Method AddItem(Name, ClassName) As %Boolean
{
	Set Seen = $Data(..Checked(Name))
	If Seen Quit 0
	Set ..Checked(Name) = ""
	
	If $Extract(Name) = "%" Quit 0
	If Name ? 1"Ens."1.E Quit 0
	If Name ? 1"EnsLib."1.E Quit 0
	If Name ? 1"EnsPortal."1.E Quit 0
	If Name ? 1"HS."1.E Quit 0
	If Name ? 1"HSFHIR."1.E Quit 0
	If Name ? 1"HSMOD."1.E Quit 0
	If Name ? 1"CSPX."1.E Quit 0
	If Name = "Ensemble.inc" Quit 0
	
	Set Type = $Piece(Name, ".", *)
	Set Item = $Piece(Name, ".", 1, *-1)
	
	If Type = "cls", '##class(%Dictionary.ClassDefinition).%ExistsId(Item) {
		If ..Warn Write ..BuildMsg("Warning: class {} referenced in {} not found.", Name, ClassName),!
		Quit 0
	}
	
	Set ..Dependencies(Name) = ClassName
	
	Quit 1
}

/// Assemble a message with placeholders
ClassMethod BuildMsg(Message As %String, Args... As %String) As %String
{
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), , 1)
	}
	
	Quit Message
}

/// Helper for creating updated status
ClassMethod BuildStatus(Message As %String, Status As %Status = "", Args... As %String) As %Status
{
	; Replace message parameters, if any
	If $Get(Args) Set Message = ..BuildMsg(Message, Args...)
	
	;Convert message to %Status
	Set MsgStatus = $System.Status.Error($$$GeneralError, Message)
	
	;Append status from parameter, if specified
	If Status '= "" Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	
	Quit MsgStatus
}

}
