Include Strix

Class Strix.XML.ToClass Extends %RegisteredObject
{

/* ToDo

Support overrides at various levels. E.g., guessing the property type
may get it wrong, so support e.g. a Types array:

Do o.Types.SetAt("%Date(FORMAT=4)", "birthdate")

--

Allow specifying "collection of things" (think of Caché export file):
all elements at a certain level can occur in unspecified order. This
means that these elements must have a common superclass (<element>Members),
and the members are specified as:

Property Members As list of <element>Member(XMLPROJECTION="ELEMENT");

--

Make XMLUSEEMPTYELEMENT configurable. This is useful, if the input has
them, for roundtrip testing.


*/

// ===== Configuration

/// The package to create the classes in
Property Package As %String;

/// Always add the XMLNAME parameter (1) or only if different from
/// Caché property name (0)
Property XmlName As %Boolean [ InitialExpression = 1 ];

// ===== Scratch data

/// Index in process private global to store parse tree
Property NodeIdx As %Integer [ Internal ];

/// Names of created classes
Property ClassNames As %String [ MultiDimensional ];

// =====

ClassMethod Create(XMLFile As %String, Package As %String, Output RootClassName As %String) As %Status
{
	Quit ..%New().CreateInt(XMLFile, Package, .RootClassName)
}

Method CreateInt(XMLFile As %String, Package As %String, Output RootClassName As %String) As %Status
{
	Set ..NodeIdx = $Increment(^||Parser)
	Kill ^||Parser(..NodeIdx)
	
	Set sc = ..CreateParseTree(XMLFile)
	If 'sc Quit sc
	
	Set ..Package = Package
	Set sc = ..CreateClasses(.RootClassName)
	If 'sc Quit sc
	
	Kill ^||Parser(..NodeIdx)
	
	Quit $$$OK
}

// ===== Class generation related code

Method CreateClasses(Output RootClassName As %String) As %Status
{
	Set RootName = $Order(^||Parser(..NodeIdx, "s", ""))
	Set RootNode = $Name(^||Parser(..NodeIdx, "s", RootName))
	
	Set sc = ..CreateClass(RootNode, .RootClassName)
	If 'sc Quit sc
	
	Quit $$$OK
}

Method CreateClass(Node As %String, Output ClassName As %String) As %Status
{
	Set Path = ..NodeRefToPath(Node)
	Set Data = @Node
	Set Properties = $lg(Data, 1)
	Set Attributes = $lg(Data, 2)
	
	Set ClassName = ..GetClassName(Path, .ClassXMLName)
	
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ClassName) {
		Set sc = $System.OBJ.Delete(ClassName, "-d")
		If 'sc Quit ..HandleError("Error deleting class {}", sc, ClassName)
	}
	
	;Write "Creating "_ClassName,!
	
	Set SeqNr = 0
	
	Set ClassDef = ##class(%Dictionary.ClassDefinition).%New(ClassName, 25)
	Set ClassDef.Super = "%SerialObject,%XML.Adaptor"
	
	If 0 { ;TBD: make this configurable
		Set sc = ..AddParameter(ClassDef, "XMLUSEEMPTYELEMENT", 1, .sc)
		If 'sc Quit ..HandleError("Error adding parameter", sc)
	}
	
	If ..XmlName || ($Piece(ClassName, ".", *) '= ClassXMLName) {
		Set ParmDef = ..AddParameter(ClassDef, "XMLNAME", ClassXMLName, .sc)
		If 'sc Quit ..HandleError("Error adding parameter", sc)
		Set ParmDef.SequenceNumber = $Increment(SeqNr)
	}
	
	;Elements and properties both generate properties
	Set AttrLen = $Select(Attributes = "": 0, 1: $Length(Attributes, ","))
	Set Combined = $Select(
	    (Attributes '= "") && (Properties '= ""): Attributes_","_Properties,
	    1: Attributes_Properties)
	
	
	;== Create properties
	
	For i = 1:1:$Length(Combined, ",") {
		Set IsAttribute = i <= AttrLen
		
		Set XMLName = $Piece(Combined, ",", i)
		Set PropName = ..GetCacheName(IsAttribute, Path, XMLName)
		
		If 'IsAttribute {
			Set PropNode = $Name(@Node@(XMLName))
			Set PropData = @PropNode
		} Else {
			Set PropNode = $Name(@Node@("@"_XMLName))
			Set PropData = $Get(@PropNode)
		}
		
		Set IsClass = $lg(PropData, 1)_$lg(PropData, 2) '= ""
		Set IsList = +$lg(PropData, 3)
		Set SetMaxlen = +$lg(PropData, 5)
		
		If IsClass {
			Set sc = ..CreateClass(PropNode, .PropType)
			If 'sc Return ..HandleError("Error creating class {} for property {}:{}:", sc, PropType, ClassName, PropName)
		} Else {
			Set PropType = ..GetPropertyType(Path_"/"_$Select(IsAttribute: "@", 1:"")_XMLName)
		}
		
		#dim PropDef As %Dictionary.PropertyDefinition
		Set PropDef = ..AddProperty(ClassDef, PropName, PropType, .sc)
		If 'sc Return ..HandleError("Error adding property {}:", sc, PropName)
		Set PropDef.SequenceNumber = $Increment(SeqNr)
		
		If IsList {
			Set PropDef.Collection = "list"
			Do PropDef.Parameters.SetAt("ELEMENT", "XMLPROJECTION")
			
		} ElseIf IsAttribute {
			Do PropDef.Parameters.SetAt("ATTRIBUTE", "XMLPROJECTION")
			
		}
		
		If ..XmlName || (PropName '= XMLName) {
			Do PropDef.Parameters.SetAt(XMLName, "XMLNAME")
		}
		
		; Don't set maxlen on non-datatype property
		If SetMaxlen, PropType = "%String" Do PropDef.Parameters.SetAt("", "MAXLEN")
	}
	
	; Special case: if this class has only attributes, it may need
	; an additional property for the element's contents.
	If Properties = "" {
		Set PropDef = ..AddProperty(ClassDef, "content", "%String", .sc)
		If 'sc Return ..HandleError("Error adding property 'content':", sc)
		Set PropDef.SequenceNumber = $Increment(SeqNr)
		Do PropDef.Parameters.SetAt("CONTENT", "XMLPROJECTION")
		If SetMaxlen Do PropDef.Parameters.SetAt("", "MAXLEN")
	}
	
	Set sc = ClassDef.%Save()
	If 'sc Quit ..HandleError("Error saving classdef for {}", sc, ClassName)
	
	
	Quit $$$OK
}

Method AddParameter(ClassDef As %Dictionary.ClassDefinition, Name As %String, Value As %String, Output Status As %Status) As %Dictionary.ParameterDefinition
{
	#dim Def As %Dictionary.ParameterDefinition
	Set Def = ##class(Strix.Generator.Utilities).GetInCollection(ClassDef.Parameters, Name, 1, .Status)
	If 'Status Quit ""
	Set Def.Default = Value
	Quit Def
}

Method AddProperty(ClassDef As %Dictionary.ClassDefinition, Name As %String, Type As %String, Output Status As %Status) As %Dictionary.PropertyDefinition
{
	#dim Def As %Dictionary.PropertyDefinition
	Set Def = ##class(Strix.Generator.Utilities).GetInCollection(ClassDef.Properties, Name, 1, .Status)
	If 'Status Quit ""
	
	; Support passing property parameters in CDL syntax.
	If Type [ "(" {
		Set Parms = $Piece($Piece(Type, "(", 2), ")", 1)
		Set Type = $Piece(Type, "(", 1)
		For i = 1:1:$Length(Parms, ",") {
			Set Parm = $Piece(Parms, ",", i)
			Set ParmName = $ZStrip($Piece(Parm, "=", 1), "<>W")
			Set ParmValue = $ZStrip($Piece(Parm, "=", 2), "<>W")
			Set ParmValue = ##class(Strix.Lib.String).UnQuote(ParmValue)
			Do Def.Parameters.SetAt(ParmValue, ParmName)
		}
	}
	
	Set Def.Type = Type
	
	Quit Def
}

/// Determines the type of a property. By defaults examines the collected
/// data. 
Method DetermineType(Path As %String) As %String
{
	Do ..GetNodeRef(Path, , .NodeRef)
	Set Data = @NodeRef
	
	;If this node has subelements or attributes it must be a class
	If ($lg(Data, 1) '= "") || ($lg(Data, 2) '= "") {
		Set Type = ..GetClassName(Path)
	} Else {
		Set Type = ..GetPropertyType(Path)
	}
	
	Quit Type
}

// ===== Configuration: can be overridden in subclass

/// Convert an XML name to a property name.
/// - Type: 0=Property, 1=Attribute, 2=ClassName
/// - Path: parent path for property and attribute, own path for classname
/// - PropertyName: the XML name to convert
Method GetCacheName(Type As %Integer, Path As %String, PropertyName As %String) As %String
{
	;Compatibility with ISC implementation: leading _ maps to %
	If $Extract(PropertyName) = "_" Set $Extract(PropertyName) = "%"
	
	;Compatibility with ISC implementation: leading number prefixed with X
	If $Extract(PropertyName) ?1N Set PropertyName = "X"_PropertyName
	
	;Convert dash-separated name to camel case
	If PropertyName ? 1.AN1.(1"-"1.AN) {
		Set Temp = ""
		For i = 1:1:$Length(PropertyName, "-") {
			Set Piece = $Piece(PropertyName, "-", i)
			Set $Extract(Piece) = $ZConvert($Extract(Piece), "U")
			Set Temp = Temp_Piece
		}
		Set PropertyName = Temp
	}
	
	;Convert underscore-separated name to camel case
	If PropertyName ? 1.AN1.(1"_"1.AN) {
		Set Temp = ""
		For i = 1:1:$Length(PropertyName, "_") {
			Set Piece = $Piece(PropertyName, "_", i)
			Set $Extract(Piece) = $ZConvert($Extract(Piece), "U")
			Set Temp = Temp_Piece
		}
		Set PropertyName = Temp
	}
	
	Set PropertyName = $Translate(PropertyName, "_-.", "")
	
	Quit PropertyName
}

/// Determine the name of the class to create for a given path.
/// The XML name (last node of the path) is returned as well.
Method GetClassName(Path As %String, Output XMLName As %String) As %String
{
	Set XMLName = $Piece(Path, "/", *)
	Set Name = ..GetCacheName(2, Path, XMLName)
	Set Name = ..Package_"."_Name
	
	Set NameUC = $ZConvert(Name, "U")
	
	If '$Data(..ClassNames(NameUC)) {
		Set ..ClassNames(NameUC) = ""
		Quit Name
	}
	
	;Make unique by adding numerical suffix
	For i = 1:1 If '$Data(..ClassNames(NameUC_i)) Quit
	
	Set Name = Name_i, ..ClassNames(NameUC_i) = ""
	
	Quit Name
}

/// Determines the type of a (datatype) property, by examining the collected
/// data.
Method GetPropertyType(Path As %String) As %String
{
	Set Node = $Name(^||Parser(..NodeIdx, "v", Path))
	
	;Start assuming anything is possible
	Set Chk("%TimeStamp") = 1
	Set Chk("%Date") = 1
	Set Chk("%Float") = 1
	Set Chk("%Integer") = 1
	Set Chk("%Boolean") = 1
	
	;Loop through values
	Set Value = ""
	For  {
		Set Value = $Order(@Node@(Value))
		If Value = "" Quit
		
		If $Data(Chk("%TimeStamp")), ##class(%TimeStamp).XSDToLogical(Value) = "" {
			Kill Chk("%TimeStamp")
		}
		If $Data(Chk("%Date")), Value '? 4N1"-"2N1"-"2N Kill Chk("%Date")
		If $Data(Chk("%Float")), Value '? .N.1(1"."1.N) Kill Chk("%Float")
		If $Data(Chk("%Integer")), Value '? 1.N Kill Chk("%Integer")
		If $Data(Chk("%Boolean")), '$lf($lb("true", "false", 1, 0), Value) Kill Chk("%Boolean")
	}
	
	; Count options left
	Set key = "", Chk = 0
	For  Set key = $Order(Chk(key)) Quit:key=""  Set Chk = Chk + 1
	
	;If only one option left, return it
	If Chk = 1 Quit $Order(Chk(""))
	
	;If %Integer is valid, %Float is too, but not the other way around
	If Chk = 2, $Data(Chk("%Integer")), $Data(Chk("%Float")) Quit "%Integer"
	
	;If multiple or no options left here, default to string.
	
	Quit "%String"
}

// ===== Parse tree related code

/// Creates a parse tree for the XML document to be used to create the
/// proxy classes with.
Method CreateParseTree(XMLFile As %String) As %Status
{
	#dim Reader As %XML.TextReader
	Set sc = ##class(%XML.TextReader).ParseFile(XMLFile, .Reader)
	If 'sc Quit ..HandleError("Error parsing XML file '{}'.", sc, XMLFile)
	
	/*
	Structure:
	 Tree("s",PropName,PropName,...) = $lb(propertynames, attributenames, islist, , lastparentseq)
	Values:
	 Tree("v",path,value)=""
	Context:
	 Tree("c",path)=lastelement
	Sequence (list detection):
	 Tree("q",path)=seqnr
	*/
	
	Set PrevParent = "", LastElementName = ""
	While Reader.Read() {
		
		If Reader.NodeType = "element" {
			Set Path = Reader.Path, Name = Reader.LocalName
			
			;== If this is the root node, record and continue
			
			If Reader.Depth = 1 {
				If Reader.HasAttributes {
					Do ..HandleAttributes(Reader, $Name(^||Parser(..NodeIdx, "s", Name)))
				} Else {
					Set ^||Parser(..NodeIdx, "s", Name) = ""
				}
				Set ^||Parser(..NodeIdx, "q", Path) = 1
				Continue
			}
			
			
			; Sequence number: if an element occurs more than once we detect that here
			If $Increment(^||Parser(..NodeIdx, "q", Path)) {}
			Set ParentPath = $Piece(Path, "/", 1, *-1)
			Set CurrentParentSeq = ^||Parser(..NodeIdx, "q", ParentPath)
			
			; Get reference to current and parent nodes
			Set Exists = ..GetNodeRef(Path, .ParentNodeRef, .NodeRef)
			
			; Check attributes
			If Reader.HasAttributes Do ..HandleAttributes(Reader, NodeRef)
			
			
			If Exists {
				; Seen this node before.
				
				; Get sequence of parent we saw this node in the previous time, and update
				Set PrevParentSeq = $lg(@NodeRef, 5)
				Set $li(@NodeRef, 5) = CurrentParentSeq
				
				; Two instances in the same parent mean a list
				If CurrentParentSeq = PrevParentSeq Set $List(@NodeRef, 3) = 1
				Continue
				
			}
			
			; === New node
			
			; Record current parent
			Set $List(@NodeRef, 5) = CurrentParentSeq
			
			
			;== Check for/get the previous element at this level
			
			Set Parent = $Piece(Path, "/", 1, *-1)
			Set PrevName = $Get(^||Parser(..NodeIdx, "c", Parent))
			Set ^||Parser(..NodeIdx, "c", Parent) = Name
			Kill Parent
			
			
			;== Check parent
			
			Set ParentData = @ParentNodeRef
			Set PropList = $lg(ParentData, 1)
			
			If PropList = "" {
				;First property in this parent
				Set $List(ParentData, 1) = Name
				Set @ParentNodeRef = ParentData
				Continue
			}
			
			
			;== Determine where this property belongs
			
			; If no data elements in this parent before this one, insert in front
			If PrevName = "" {
				Set PropList = Name_","_PropList
				Set $List(@ParentNodeRef, 1) = PropList
				Continue
			}
			
			; Find previous element in property list
			For i = 1:1:$Length(PropList, ",") {
				If $Piece(PropList, ",", i) = PrevName {
					Set Before = $Piece(PropList, ",", 1, i)
					Set After = $Piece(PropList, ",", i+1, *)
					Quit
				}
			}
			
			; Insert property after the previous name at this level
			Set PropList = Before_","_Name
			If After '= "" Set PropList = PropList_","_After
			
			Set $List(@ParentNodeRef, 1) = PropList
			
			
		} ElseIf Reader.NodeType = "endelement" {
			Set Path = Reader.Path
			Kill ^||Parser(..NodeIdx, "c", Path)
			
			
		} ElseIf Reader.NodeType = "chars" {
			;== Store each value for later analysis
			Set Path = Reader.Path, Value = Reader.Value
			Set Len = $Length(Value)
			If Len > 50 {
				Set Value = $Extract(Value, 1, 30)
				Do ..GetNodeRef(Path, , .NodeRef)
				Set $List(@NodeRef, 5) = 1
			}
			Set ^||Parser(..NodeIdx, "v", Path, Value) = ""
			
		}
	}
	
	Quit $$$OK
}

/// Handles attributes for the current element in Reader. Updates the
/// list of attribute names in the structure node, and stores values
/// under @AttributeName in the value node.
Method HandleAttributes(Reader As %XML.TextReader, Node As %String)
{
	Set Data = $Get(@Node), AttributeList = $ListGet(Data, 2)
	
	Set List = $ListFromString(AttributeList)
	Set Path = Reader.Path
	For i = 1:1:Reader.AttributeCount {
		Do Reader.MoveToAttributeIndex(i)
		
		Set Name = Reader.LocalName
		Set Value = Reader.Value
		
		If '$ListFind(List, Name) Set List = List_$lb(Name)
		
		If Value '= "" {
			Set ^||Parser(..NodeIdx, "v", Path_"/@"_Name, Value) = ""
			;If length > 50: remember
			If $Length(Value) > 50 {
				Set AttrData = $Get(@Node@("@"_Name))
				Set $List(AttrData, 5) = 1
				Set @Node@("@"_Name) = AttrData
			}
		}
	}
	
	Set $List(Data, 2) = $ListToString(List)
	Set @Node = Data
	
	Quit
}

/// Returns a reference to the current and parent nodes in the structure
/// tree for the given path, in output parameters. Return value is the
/// last sequence number for this element, or "" if this is a new one.
Method GetNodeRef(Path As %String, Output ParentNodeRef As %String, Output NodeRef As %String) As %Integer
{
	;Get reference to parent node
	Set ParentNodeRef = $Name(^||Parser(..NodeIdx, "s"))
	For i = 2:1:$Length(Path, "/") - 1 {
		Set Name = $Piece(Path, "/", i)
		Set ParentNodeRef = $Name(@ParentNodeRef@(Name))
	}
	
	;Get reference to current node
	Set Name = $Piece(Path, "/", *)
	Set NodeRef = $Name(@ParentNodeRef@(Name))
	
	;Check and return whether it exists
	Set LastSeq = $ListGet($Get(@NodeRef), 5)
	
	Quit LastSeq
}

/// Given a node reference, returns an XML-style path for it.
Method NodeRefToPath(Node As %String) As %String
{
	Set Path = ""
	;Skip ..NodeIdx and "s"
	For i = 3:1:$QLength(Node) Set Path = Path_"/"_$QSubscript(Node, i)
	Quit Path
}

/// Debugging aid: shows how %XML.TextReader parses an XML document. Based on
/// the example in the documentation.
ClassMethod ShowTree(XMLFile As %String)
{
	#dim Reader As %XML.TextReader
	Set sc = ##class(%XML.TextReader).ParseFile(XMLFile, .Reader)
	If 'sc Quit ..HandleError("Error parsing XML file '{}'.", sc, XMLFile)
	
	While Reader.Read() {
		Set Indent = $Justify("", $Length(Reader.Path, "/") * 2)
		
		Write !, Indent, "Node ", Reader.seq, " is a(n) ", Reader.NodeType
		If Reader.Name '= "" {
			Write " named: ", Reader.Name
		} Else {
			Write " and has no name"
		}
		
		Write !, Indent, "    path: ", Reader.Path
		
		If Reader.Value'="" Write !, Indent, "    value: ", Reader.Value
		
		If Reader.NodeType = "endelement" Write !
	}
	
	Quit
}

// ===== Helpers

/// Builds a status from a message and an existing status. If the principal
/// device is a terminal, displays the error. Returns the new status.
ClassMethod HandleError(Message As %String, Status As %Status, Args... As %String) As %Status
{
	Set Status = $$$BuildErr(Message, Status, Args...)
	
	If $$$IsTerm {
		Do $System.Status.DisplayError(Status)
	}
	
	Quit Status
}

}

