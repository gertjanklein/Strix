Include Strix

Class Strix.JSON.ToClass Extends %RegisteredObject
{

/// Index in process private global to store parse tree
Property NodeIdx As %Integer [ Internal ];

/// Package to create classes in
Property Package As %String;

/// Stores class names for duplicate detection
Property ClassNames As %String [ MultiDimensional ];

// =====

/// Create classes that can be used to parse the passed-in JSON object.
ClassMethod Create(JSON As %DynamicAbstractObject, ClassName As %String) As %Status
{
	Quit ..%New().CreateInt(JSON, ClassName)
}

/// Create classes that can be used to parse the JSON in the specified file.
ClassMethod CreateFromFile(FileName As %String, ClassName As %String) As %Status
{
	Set JSON = ##class(%DynamicAbstractObject).%FromJSON(FileName)
	Quit ..%New().CreateInt(JSON, ClassName)
}

// -----

/// Converts a JSON property name to the Caché version.
Method GetPropertyName(Name As %String) As %String
{
	; Convert dash- or underscore-separated names to CamelCase
	While $Locate(Name, "[-_]", , End) {
		Set $Extract(Name, End) = $ZConvert($Extract(Name, End), "U")
		Set $Extract(Name, End-1) = ""
	}
	
	; Start with a capital letter
	Set $Extract(Name) = $ZConvert($Extract(Name), "U")
	
	; Cater for all-numeric name
	If Name ? 1.N Set Name = "n"_Name
	
	Quit Name
}

/// Converts a JSON object name to the Caché class name.
Method GetClassName(ClassShortName As %String) As %String
{
	; Use same basic rules as for properties:
	Set ClassShortName = ..GetPropertyName(ClassShortName)
	
	; Find unique classname in case of duplicates
	For Suffix = 0:1 {
		If Suffix = 0 Set Suffix = ""
		Set ClassName = ClassShortName_Suffix
		Set $Extract(ClassName) = $ZConvert($Extract(ClassName), "U")
		If '$Data(..ClassNames(ClassName)) Quit
	}
	
	Set ..ClassNames(ClassName) = ""
	
	Quit ClassName
}

// =====

/// Implementation of the JSON to class code.
Method CreateInt(JSON As %DynamicAbstractObject, ClassName As %String) As %Status
{
	Set ..NodeIdx = $Increment(^||Parser)
	Set TopNode = $Name(^||Parser(..NodeIdx))
	Kill @TopNode
	
	Set ..Package = $$$ClassPackageName(ClassName)
	Set ShortName = $$$ClassShortName(ClassName)
	
	Set sc = ..CreateParseTree(JSON, TopNode)
	If 'sc Quit sc
	
	Set sc = ..CreateClass(ShortName, TopNode)
	If 'sc Quit sc
	
	Set sc = $System.OBJ.Compile(ClassName, "ck-drb")
	If 'sc Quit $$$BuildStatus("Error compiling class '{}:", Status, ClassName)
	
	Kill @TopNode
	
	Quit $$$OK
}

// =====

/// Creates the top-level class, and any related classes, based on
/// the parse tree created before.
Method CreateClass(ByRef ClassName As %String, Node As %String) As %Status
{
	Set ClassName = ..Package_"."_..GetClassName(ClassName)
	
	#dim ClassDef As %Dictionary.ClassDefinition
	Set sc = ..CreateClassDef(ClassName, , .ClassDef)
	If 'sc Quit sc
	
	Set PropertyNames = ..GetPropList($Name(@Node@(2)))
	For i = 1:1:$ListLength(PropertyNames) {
		Set PropertyName = $List(PropertyNames, i)
		
		Set Name = ..GetPropertyName(PropertyName)
		
		Set Type = $Piece(@Node@(3, PropertyName, 1), ":")
		Set IsList = $Piece(@Node@(3, PropertyName, 1), ":", 2) = "array"
		Set Collection = $Select(IsList: "list", 1: "")
		
		; Type: null, boolean, number, oref, object, array, string, unassigned
		
		If Type = "string" {
			Set pd = ..AddProperty(ClassDef, Name, "%String", Collection)
			
		} ElseIf Type = "boolean" {
			Set pd = ..AddProperty(ClassDef, Name, "%Boolean", Collection)
			
		} ElseIf Type = "number" {
			Set pd = ..AddProperty(ClassDef, Name, "%Numeric", Collection)
			
		} Else {
			; Object
			
			Set PropClassName = PropertyName
			Set PropNodeName = $Name(@Node@(3, PropertyName))
			
			Set sc = ..CreateClass(.PropClassName, PropNodeName)
			If 'sc Return sc
			
			Set pd = ..AddProperty(ClassDef, Name, PropClassName, Collection)
		}
		
		Do pd.Parameters.SetAt(PropertyName, "JSONNAME")
	}
	
	Set sc = ClassDef.%Save()
	If 'sc Quit sc
	
	Quit $$$OK
}

// =====

/// Parses the JSON and creates a parse tree to use to create the
/// classes with.
Method CreateParseTree(JSON As %DynamicAbstractObject, Node As %String) As %Status
{
	Set IsList = JSON.%ClassName() = "%DynamicArray"
	If IsList {
		Set @Node = "array"
		Quit ..ParseArray(Node, JSON)
	}
	
	Set @Node@(1) = "object"
	
	Quit ..ParseObject(Node, JSON)
}

/// Creates the parse tree subnode for the given JSON object.
Method ParseObject(Node As %String, Object As %DynamicObject) As %Status
{
	#dim it As Strix.JSON.Iterator
	Set it = ##class(Strix.JSON.Iterator).GetIterator(Object)
	
	Set PropList = ""
	While it.GetNext(.Name, .Value, .Type) {
		; Type: null, boolean, number, oref, object, array, string, unassigned
		If Type = "oref" Continue
		If Type = "unassigned" Continue
		
		Set PropList = PropList_$lb(Name)
		
		Set @Node@(3, Name, 1) = Type
		If Type = "object" {
			Set sc = ..ParseObject($Name(@Node@(3, Name)), Value)
			If 'sc Return sc
			
		} ElseIf Type = "array" {
			Set sc = ..ParseArray($Name(@Node@(3, Name)), Value)
			If 'sc Return sc
			
		}
	}
	
	; Save collected list of properties
	Do ..AddPropList($Name(@Node@(2)), PropList)
	
	Quit $$$OK
}

/// Creates the parse tree subnode for the given JSON array.
Method ParseArray(Node As %String, Array As %DynamicArray) As %Status
{
	#dim it As Strix.JSON.Iterator
	Set it = ##class(Strix.JSON.Iterator).GetIterator(Array)
	
	Set PrevType = ""
	While it.GetNext(.Name, .Value, .Type) {
		If PrevType = "" {
			Set PrevType = Type
			Set @Node@(1) = Type_":"_@Node@(1)
		} Else {
			If PrevType '= Type {
				; Allow "downcasting" number to string
				If PrevType = "number", Type = "string" {
					Set PrevType = "string"
					Set $Piece(@Node@(1), ":") = Type
				} ElseIf (PrevType '= "string") || (Type '= "number") {
					Set Msg = "Processing failed at {}: inconsistent data in array ({}/{}) not supported."
					Return $$$BuildStatus(Msg, , Node, PrevType, Type)
				}
			}
		}
		
		If Type = "object" {
			Set sc = ..ParseObject(Node, Value)
			If 'sc Return sc
			
		} ElseIf Type = "array" {
			Set sc = ..ParseArray(Node, Value)
			If 'sc Return sc
			
		}
	}
	
	Quit $$$OK
}

/// Saves a list of object properties. Prevents duplicates
/// from being stored.
Method AddPropList(Node As %String, PropList As %List)
{
	; Prevent duplicates
	For i = 1:1:$Get(@Node) {
		If $ListSame(@Node@(i), PropList) Return
	}
	Set @Node@($Increment(@Node)) = PropList
	Quit
}

/// Returns a list of all properties for an object. Current
/// implementation just returns the longest list found.
Method GetPropList(Node As %String) As %List
{
	Set Longest = ""
	For i = 1:1:$Get(@Node) {
		Set Test = @Node@(i)
		If $ll(Test) > $ll(Longest) Set Longest = Test
	}
	Quit Longest
}

// =====

/// Helper: creates and returns a class definition object.
Method CreateClassDef(ClassName As %String, Super As %String = "%SerialObject,Strix.JSON.Adaptor", Output ClassDef As %Dictionary.ClassDefinition) As %Status
{
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ClassName) {
		Set sc = ##class(%Dictionary.ClassDefinition).%DeleteId(ClassName)
		If 'sc Quit $$$BuildStatus("Error deleting existing class '{}'", sc, ClassName)
	}
	
	; Prevent unwanted "[ Inheritance = right ]" by specifying
	; class version 25.
	Set ClassDef = ##class(%Dictionary.ClassDefinition).%New(ClassName, 25)
	Set ClassDef.Super = Super
	Set ..ClassNames(ClassName) = ClassDef
	
	Quit $$$OK
}

/// Helper: creates and returns a property definition object for the
/// given class definition.
ClassMethod AddProperty(ClassDef As %Dictionary.ClassDefinition, Name As %String, Type As %String, Collection As %String = "", SeqNr As %Integer = "") As %Dictionary.PropertyDefinition
{
	Set Property = ##class(%Dictionary.PropertyDefinition).%New()
	Set Property.Name = Name
	Set Property.Type = Type
	Set Property.Collection = Collection
	If SeqNr '= "" {
		Set Property.SequenceNumber = SeqNr
	} Else {
		Set Property.SequenceNumber = ClassDef.Properties.Count() + 1
	}
	Do ClassDef.Properties.Insert(Property)
	Quit Property
}

}
