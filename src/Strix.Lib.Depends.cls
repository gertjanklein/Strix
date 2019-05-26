Include %occErrors

Class Strix.Lib.Depends Extends %RegisteredObject
{

Property Checked As %String [ MultiDimensional ];

Property Dependencies As %String [ MultiDimensional ];

// -----

/// Cached regex objects (performance)
Property Matchers As array Of %Regex.Matcher;

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
			
			Do ..AddItem(Item_".cls", Item)
			Set sc = ..CheckItem(Item_".cls")
			If 'sc Return ..BuildStatus("Error checking '{}':", sc, Item)
		}
	}
	
	Quit $$$OK
}

/// Checks dependencies for a single item.
Method CheckItem(Item As %String, Recursive As %Boolean = 1) As %Status
{
	Set Type = $ZConvert($Piece(Item, ".", *), "l")
	If Type = "cls" {
		Set sc = ..CheckClass($Piece(Item, ".", 1, *-1))
		If 'sc Quit sc
		
	} Else {
		Quit ..BuildStatus("Error: unsupported type '{}'.",, Type)
	}
	
	Set Dep = ""
	For  {
		Set Dep = $Order(..Dependencies(Dep), 1, ReferencedBy)
		If Dep = "" Quit
		If $Data(..Checked(Dep)) Continue
		
		Set Type = $Piece(Dep, ".", *)
		If Type = "cls" {
			Set Cls = $Piece(Dep, ".", 1, *-1)
			If '##class(%Dictionary.ClassDefinition).%ExistsId(Cls) {
				Write "Warning: dependency "_Cls_" of "_ReferencedBy_" does not exist.",!
				Set ..Checked(Dep) = ""
				Continue
			}
			
			If Recursive {
				Set sc = ..CheckItem(Dep)
				If 'sc Return ..BuildStatus("Error checking dependency {}:", sc, Dep)
			}
		}
	}
	
	Quit $$$OK
}

/// Checks a single class for its dependencies
Method CheckClass(ClassName As %String) As %Status
{
	Set ..Checked(ClassName_".cls") = ""
	
	; Start with what this returns:
	Set sc = $System.OBJ.GetDependencies(ClassName, .Items, "ckrby")
	If 'sc Quit ..BuildStatus("Error from system for class {}:", sc, ClassName)
	
	Set Item = ""
	For  {
		Set Item = $Order(Items(Item))
		If Item = "" Quit
		Set Name = Item_".cls"
		If '$Data(..Checked(Name)) Do ..AddItem(Name, ClassName)
	}
	
	
	Set Def = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .sc)
	If 'sc Quit ..BuildStatus("Error opening definition for class {}:", sc, ClassName)
	
	#define AddCsv(%t,%l) If %l '="" {For i = 1:1:$l(%l,",") Set n=$p(%l,",",i)_%t i $e(n)'="%",'$d(..Checked(n)) Do ..AddItem(n, ClassName)}
	
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
Method CheckCode(Code As %Stream, Package As %String = "User", ClassName = "") As %Status
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
				If '$Data(..Checked(Item)) Do ..AddItem(Item, ClassName)
			}
		}
	}
	
	Quit $$$OK
}

// =====

/// Adds an item to the dependency array, after checking that
/// it is not a system item.
Method AddItem(Name, ClassName)
{
	If $Extract(Name) = "%" Quit
	If Name ? 1"Ens."1.E Quit
	If Name ? 1"EnsLib."1.E Quit
	If Name ? 1"EnsPortal."1.E Quit
	If Name ? 1"CSPX."1.E Quit
	Set ..Dependencies(Name) = ClassName
	Quit
}

/// Helper for creating updated status
ClassMethod BuildStatus(Message As %String, Status As %Status = "", Args... As %String) As %Status
{
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), 1, 1)
	}
	
	;Convert message to %Status
	Set MsgStatus = $System.Status.Error($$$GeneralError, Message)
	
	;Append status from parameter, if specified
	If Status '= "" Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	
	Quit MsgStatus
}

}

