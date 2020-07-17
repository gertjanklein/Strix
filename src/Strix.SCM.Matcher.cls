Include Strix.SCM

/// Matches item patterns.
Class Strix.SCM.Matcher Extends %RegisteredObject
{

/// Item specifications to match against
Property SpecList As list Of %String;

/// The patterns generated from the specs, for re-use
Property Patterns As array Of %String;

// =====

/// Constructor, pass in the list of project member specifications
Method %OnNew(SpecList As %ListOfDataTypes = "") As %Status [ Private, ServerOnly = 1 ]
{
	If SpecList Set ..SpecList = SpecList
	Quit $$$OK
}

/// Returns a boolean indicating whether an item matches any of the specs here.
Method Matches(Item As %String, Output AsItem As %Boolean, Output AsStorage As %Boolean) As %Boolean
{
	Set (AsItem, AsStorage) = 0
	
	; Studio may pass multiple items as a comma-separated list.
	If Item [ "," Quit 0
	
	;Convert type to lowercase
	$$$NormalizeType(Item)
	Set ItemType = $$$ItemType(Item)
	Set ItemName = $$$ItemName(Item)
	
	; Sometimes, in Strix.SCM.Studio:OnAfterLoad(), an item ".CLS" (no
	; name, no Object parameter either) comes in. Check for an empty name
	; here, and just ignore.
	If ItemName = "" Quit 0
	
	; Some generated items may need to be exported, but most won't
	Set IsGenerated = (ItemType = "cls") && ($$$defClassKeyGet(ItemName,$$$cCLASSgeneratedby) '= "")
	
	;Treat BPL and DTL types as the classes they are
	If "bpl,dtl" [ ItemType Set $$$ItemType(Item) = "cls"
	
	;First check the negative specifications: if one of them matches we must
	;reject this item.
	Set Found = 0
	For i = 1:1:..SpecList.Count() {
		Set Spec = ..SpecList.GetAt(i)
		If $Extract(Spec) '= "-" Continue
		If $$$ItemType(Spec) = "gbl" Continue
		
		Set Pattern = ..MakePattern(Spec)
		If Item ?@Pattern Set Found = 1 Quit
	}
	If 'Found {
		;No negative spec found; check the positive specifications
		For i = 1:1:..SpecList.Count() {
			Set Spec = ..SpecList.GetAt(i)
			If $Extract(Spec) = "-" Continue
			If $$$ItemType(Spec) = "stg" Continue
			
			Set Pattern = ..MakePattern(Spec)
			If Item ?@Pattern {
				; Skip generated classes, unless they are specified explicity
				If IsGenerated, Spec [ "*" Continue
				Set Found = 1 Quit
			}
		}
		If Found Set AsItem = 1
	}
	
	;=====
	
	;Check storage:
	Set Found = 0
	For i = 1:1:..SpecList.Count() {
		Set Spec = ..SpecList.GetAt(i)
		If $Extract(Spec) '= "-" Continue
		If $$$ItemType(Spec) '= "gbl" Continue
		
		Set $Piece(Spec, ".", $Length(Spec, ".")) = "cls"
		Set Pattern = ..MakePattern(Spec)
		If Item ?@Pattern Set Found = 1 Quit
	}
	If 'Found {
		;No negative spec found; check the positive specifications
		For i = 1:1:..SpecList.Count() {
			Set Spec = ..SpecList.GetAt(i) 
			If $Extract(Spec) = "-" Continue
			If $$$ItemType(Spec) '= "stg" Continue
			
			Set $Piece(Spec, ".", $Length(Spec, ".")) = "cls"
			Set Pattern = ..MakePattern(Spec)
			If Item ?@Pattern Set Found = 1 Quit
		}
		If Found Set AsStorage = 1
	}
	
	Quit AsItem || AsStorage
}

// =====

/// Build an array of all current items matching the specifications
/// in ..SpecList.
Method GetAllMembers(Output Members As %String) As %Status
{
	;First convert all specs to patterns
	For i = 1:1:..SpecList.Count() {
		Set Spec = ..SpecList.GetAt(i)
		Set Pattern = ..MakePattern($Select($Extract(Spec) = "-": $Extract(Spec, 2, *), 1: Spec))
		Do ..Patterns.SetAt(Pattern, Spec)
	}
	
	;Get a unique node to use for temporary storage of the class list
	Set Node = $Name(^||Matcher($Increment(^||Matcher)))
	Kill @Node
	
	;Preload a list of all classes, assuming most specs are classes
	Set Status = ..GetAllClasses(Node)
	If 'Status Quit $$$BuildErr("Error getting classlist", Status)
	
	;Start with the add specs:
	Set Spec = ""
	For  {
		Set Pattern = ..Patterns.GetNext(.Spec)
		If Spec = "" Quit
		If $Extract(Spec) = "-" Continue
		
		Set Type = $$$ItemType(Spec)
		If Type = "cls" {
			;Class names are matched with the pattern
			Set Status = ..HandleClassSpec(Node, Pattern, .Members)
			
		} ElseIf (Type = "mac") || (Type = "inc") || (Type = "int") {
			;Routine names are handled using the spec
			Set Status = ..HandleRoutineSpec(Spec, .Members)
			
		} ElseIf Type = "stg" {
			Set Status = ..HandleStorageSpec(Node, Spec, Pattern, .Members)
			
		}
		If 'Status Quit
	}
	If 'Status Quit $$$BuildErr("Error handling spec '"_Spec_"'", Status)
	
	
	;Now remove everything matching the remove specs:
	Set Spec = ""
	For  {
		Set Pattern = ..Patterns.GetNext(.Spec)
		If Spec = "" Quit
		If $Extract(Spec) '= "-" Continue
		
		Set Type = $$$ItemType(Spec)
		Set Name = ""
		For  {
			Set Name = $Order(Members(Name), 1, Type)
			If Name = "" Quit
			
			If Name '? @Pattern Continue
			Kill Members(Name)
		}
	}
	
	Quit $$$OK
}

// ===== Helpers

/// Parses the specification for items of type cls, and stores
/// the result in Members.
Method HandleClassSpec(Node As %String, Pattern As %String, ByRef Members As %String) As %Status
{
	Set Name = ""
	For  {
		Set Name = $Order(@Node@(Name))
		If Name = "" Quit
		
		If Name '? @Pattern Continue
		
		Set Members(Name) = ""
	}
	
	Quit $$$OK
}

/// Parses the specification for items of type mac, int, and inc, and stores
/// the result in Members.
Method HandleRoutineSpec(Spec As %String, ByRef Members As %String) As %Status
{
	Set rs = ##class(%ResultSet).%New("%Routine:RoutineList")
	Set Status = rs.Execute(Spec)
	If 'Status Quit $$$BuildErr("Error executing routine query with spec '"_Spec_"':", Status)
	
	While rs.Next() {
		Set Name = rs.Get("Name")
		;Convert type (mac, inc, etc) to lowercase
		$$$NormalizeType(Name)
		Set Members(Name) = ""
	}
	
	Quit $$$OK
}

/// Parses the specification for items of type stg (storage), and stores the
/// result in Members.
Method HandleStorageSpec(Node As %String, Spec As %String, Pattern As %String, ByRef Members As %String) As %Status
{
	;The pattern ends in .stg, but we are looking for classes
	If Pattern '? 1.E1".stg""" Quit $$$BuildErr("Pattern spec error: '"_Pattern_"'", 1)
	Set $Extract(Pattern, *-4, *) = ".cls"""
	
	Set Status = $$$OK
	Set Name = ""
	For  {
		Set Name = $Order(@Node@(Name))
		If Name = "" Quit
		
		If Name '? @Pattern Continue
		
		Set StgName = Name, $Extract(StgName, *-3, *) = ".stg"
		
		Set Members(StgName) = ..GetStorageGlobals(Name, .Status)
		If 'Status Set Status = $$$BuildErr("Error getting storage location for class '"_Name_"' included by spec '"_Spec_"'", Status) Quit
	}
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Returns the globals used for a class's storage (if specified in the
/// standard Caché manner -- custom storage is not supported).
ClassMethod GetStorageGlobals(ClassName As %String, Output Status As %Status) As %String
{
	If ClassName ?1.E1".cls" Set ClassName = $Extract(ClassName, 1, *-4)
	
	#dim Def As %Dictionary.ClassDefinition
	Set Def = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .Status)
	If 'Status Set Status = $$$BuildErr("Can't determine storage globals for class '"_ClassName_"'", Status) Quit ""
	
	Set Key = ""
	For  {
		#dim Storage As %Dictionary.StorageDefinition
		Set Storage = Def.Storages.GetNext(.Key)
		If Key = "" Quit
		
		If Storage.Type '= "%Library.CacheStorage" {
			Set Status = $$$BuildErr("Unsupported storage type '"_Storage.Type_"'", 1)
			Quit
		}
		
		;Store in array to remove duplicates
		Set Globals(Storage.DataLocation_".gbl") = ""
		Set Globals(Storage.IdLocation_".gbl") = ""
		Set Globals(Storage.IndexLocation_".gbl") = ""
		Set Globals(Storage.StreamLocation_".gbl") = ""
	}
	If 'Status Quit ""
	
	;Convert array to comma-separated list
	Set Result = ##class(Strix.Lib.String).ListFromArray(.Globals, ",")
	
	Quit Result
}

/// Determines all available classes
Method GetAllClasses(Node As %String) As %Status
{
	Set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:Summary")
	Set Status = rs.Execute()
	If 'Status Quit $$$BuildErr("Error executing all classes query:", Status)
	
	While rs.Next() {
		If rs.Get("Hidden") Continue
		If rs.Get("System") Continue
		
		Set ClassName = rs.Get("Name")
		If $$$defClassKeyGet(ClassName,$$$cCLASSgeneratedby) '= "" Continue
		
		;Skip Ensemble system classes -- these are not marked System in this query. :(
		Set TopPackage = $Piece(ClassName, ".")
		If TopPackage = "Ens" Continue
		If TopPackage = "EnsLib" Continue
		If TopPackage = "EnsPortal" Continue
		
		Set @Node@(ClassName_".cls") = ""
	}
	
	Quit $$$OK
}

/// Converts a specification containing optional asterisks (*) as match-all
/// character to a corresponding COS pattern.
ClassMethod MakePattern(Specification As %String) As %String
{
	;Remove negation, will be handled elsewhere
	If $Extract(Specification) = "-" Set Specification = $Extract(Specification, 2, *)
	
	Set Pattern = ""
	Set Index = 0, PrevIndex = 1
	For  {
		Set Index = $Find(Specification, "*", Index)
		If Index {
			;Found an asterisk; take everything before it literal
			Set Before = $Extract(Specification, PrevIndex, Index - 2)
			If Before '= "" Set Pattern = Pattern_"1"""_Before_""""
			Set Pattern = Pattern_".E"
			Set PrevIndex = Index
			
		} Else {
			Set LastBit = $Extract(Specification, PrevIndex, $Length(Specification))
			If LastBit '= "" Set Pattern = Pattern_"1"""_LastBit_""""
			
			Quit
		}
	}
	
	Quit Pattern
}

}

