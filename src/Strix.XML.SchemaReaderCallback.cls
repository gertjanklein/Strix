Include Strix

Class Strix.XML.SchemaReaderCallback Extends %RegisteredObject
{

/// The reader we receive the callback from
Property Reader As Strix.XML.SchemaReader;

Property Classes As %String [ MultiDimensional ];

// -----

/// Global node containing the tree of classes to be generated
Property ClassTree As %String;

/// Global node for the currently processed class
Property ClassNode As %String;

/// Name of the currently processed class
Property ClassName As %String;

/// Global node for the currently processed property
Property PropertyNode As %String;

/// Name of the currently processed property
Property PropertyName As %String;

// -----

/// Count of datatype classes that were removed by ReduceDatatypeClasses
Property ReducedClasses As %Integer;

/// Classes renamed through ..RenameClass. Used to update CompileAfter
/// settings of other classes. Stored as a list to support multiple
/// renames of the same class.
Property RenamedClasses As list Of %List [ Internal ];

// =====

/// Basic entry point; can be overridden in a subclass to further
/// configure the schema reader.
ClassMethod Create(SchemaLocation As %String, Package As %String = "Test")
{
	Set Me = ..%New()
	
	; Create and configure reader
	Set Reader = ##class(Strix.XML.SchemaReader).%New()
	Set Reader.Callback = Me
	Set Reader.CompileClasses = 0
	Set Reader.MakePersistent = 0
	Set Reader.MakeSerial = 0
	
	Set sc = Me.RunReader(Reader, SchemaLocation, Package)
	If 'sc Quit ..ShowError("Error running schema reader:", sc)
	
	Quit $$$OK
}

// -----

/// Overridable method: handles a single class, after the parse tree
/// has been built but before the class is generated.
Method HandleClass(Name As %String, XmlName As %String) As %Status
{
	Quit $$$OK
}

/// Overridable method: handles a single property, after the parse tree
/// has been built but before the class is generated.
Method HandleProperty(Name As %String, XmlName As %String, Type As %String, IsDataType As %Boolean) As %Status
{
	Quit $$$OK
}

/// Callback to post-process a class after it has been created.
Method PostProcessClass(ClassName As %String, Type As %String) As %Status
{
	Quit $$$OK
}

// ===== Helpers

/// Receives a class short name or property name and its XML name,
/// and returns what it should be named.
Method GetValidName(Name As %String, XmlName As %String, Output Changed As %Boolean) As %String
{
	Set Changed = 0
	
	; If the XML name is a valid Caché name, the only possible change
	; is a numeric suffix due to duplicate names; leave that intact.
	If $ZName(XmlName, 6) Quit Name
	
	Set NewName = ""
	For i = 1:1:$Length(XmlName) {
		Set Char = $Extract(XmlName, i)
		If " _.(-" [ Char, $Extract(XmlName, i+1) ? 1A {
			Set NewName = NewName_$ZConvert($Extract(XmlName, $Increment(i)), "U")
			Continue
		}
		
		If NewName '= "" {
			;Valid as second or later character?
			If $ZName("x"_Char, 6) Set NewName = NewName_Char
		} Else {
			;Valid as first character?
			If $ZName(Char, 6) Set NewName = NewName_Char
		}
	}
	
	Set Changed = Name '= NewName
	
	Quit NewName
}

// -----

/// Changes the name of the current class.
Method RenameClass(NewName As %String) As %Status
{
	; Allow providing new name without package
	If NewName '[ "." {
		Set Package = $Piece(..ClassName, ".", 1, *-1)
		Set NewName = Package_"."_NewName
	}
	
	; Make sure XML name stays the same
	If '$Data(@..ClassNode@("Parameter", "XMLNAME")) {
		Set ShortName = $Piece(..ClassName, ".", *)
		Set @..ClassNode@("Parameter", "XMLNAME") = ShortName
	}
	
	; Remember old name for later processing.
	Do ..RenamedClasses.Insert($ListBuild(..ClassName, NewName))
	
	; Change class name
	Set @..ClassNode@("ClassName") = NewName
	Set ..ClassName = NewName
	
	Quit $$$OK
}

/// Removes the current class; it won't be created.
Method RemoveClass() As %Status
{
	Set @..ClassNode@("Removed") = 1
	Quit $$$OK
}

// -----

/// Gets a parameter for the current class
Method GetClassParameter(Name As %String) As %String
{
	Quit $Get(@..ClassNode@("Parameter", Name))
}

/// Sets a parameter for the current class
Method SetClassParameter(Name As %String, Value As %String) As %Status
{
	Set @..ClassNode@("Parameter", Name) = Value
	Quit $$$OK
}

// -----

/// Gets the CompileAfter setting for the current class
Method GetCompileAfter() As %String
{
	Quit $Get(@..ClassNode@("CompileAfter"))
}

/// Sets the CompileAfter setting for the current class
Method SetCompileAfter(Value As %String) As %Status
{
	Set @..ClassNode@("CompileAfter") = Value
	Quit $$$OK
}

// -----

/// Gets the Description for the current class
Method GetDescription() As %String
{
	Quit $Get(@..ClassNode@("Description"))
}

/// Sets the Description for the current class
Method SetDescription(Value As %String) As %Status
{
	Set @..ClassNode@("Description") = Value
	Quit $$$OK
}

// -----

/// Returns the superclass for the currently processed class
Method GetSuperClass(Output NamespaceIdx As %Integer) As %String
{
	Set Info = $Get(@..ClassNode@("Super"))
	If Info ? 1.N1"^".E {
		Set NamespaceIdx = $Piece(Info, "^", 1)
		Set SuperClass = $Piece(Info, "^", 2)
	} Else {
		Set NamespaceIdx = ""
		Set SuperClass = Info
	}
	Quit SuperClass
}

/// Changes the superclass for the currently processed class
Method SetSuperClass(SuperClass As %String) As %Status
{
	Set @..ClassNode@("Super") = SuperClass
	Quit $$$OK
}

// -----

/// Retrieves the type of the current class. Output parameter
/// NamespaceIdx receives the index in the schemareader ..NSInfo
/// property for the class.
Method GetClassType(Output NamespaceIdx As %Integer) As %String
{
	Set Info = $Get(@..ClassNode@("Type"))
	Set NamespaceIdx = $Piece(Info, "^", 1)
	Set Type = $Piece(Info, "^", 2)
	Set Ref = $Piece(Info, "^", 3)
	
	If Info ?1"^^"1.N {
		; Reference to another node; get the classname from there:
		Set ClassBase = $Name(@..ClassNode, $QLength(..ClassNode)-1)
		Set Type = @ClassBase@(Ref, "ClassName")
	}
	
	Quit Type
}

/// Sets the abstract flag for a class
Method SetClassAbstract(Abstract As %Boolean) As %Status
{
	If Abstract {
		Set @..ClassNode@("abstract") = ""
	} Else {
		Kill @..ClassNode@("abstract")
	}
	Quit $$$OK
}

// =====

/// Changes the name of the current property.
Method RenameProperty(NewName As %String) As %Status
{
	; Make sure XML name stays the same
	If '$Data(@..PropertyNode@("Parameter", "XMLNAME")) {
		Set @..PropertyNode@("Parameter", "XMLNAME") = ..PropertyName
	}
	
	; Change property name
	Set @..PropertyNode@("Name") = NewName
	Set ..PropertyName = NewName
	
	Quit $$$OK
}

/// Sets a property required flag
Method SetPropertyRequired(Required As %Boolean = 1) As %Status
{
	Set @..PropertyNode@("Required") = Required
	Quit $$$OK
}

// -----

/// Returns the collection ("list", "array", "") for the current property
Method GetPropertyCollection() As %String
{
	Quit @..PropertyNode@("Collection")
}

/// Sets the collection ("list", "array", "") for the current property
Method SetPropertyCollection(Collection As %String)
{
	Set @..PropertyNode@("Collection") = Collection
}

// -----

/// Gets a property parameter for the current property
Method GetPropertyParameter(Name As %String) As %String
{
	Quit $Get(@..PropertyNode@("Parameter", Name))
}

/// Sets a property parameter for the current property
Method SetPropertyParameter(Name As %String, Value As %String) As %Status
{
	Set @..PropertyNode@("Parameter", Name) = Value
	Quit $$$OK
}

/// Removes a property parameter for the current property
Method KillPropertyParameter(Name As %String)
{
	Kill @..PropertyNode@("Parameter", Name)
}

// -----

/// Sets the type for the current property
Method SetPropertyType(Type As %String)
{
	Set @..PropertyNode@("Type") = Type
}

// ===== Additional helpers

/// Runs the schema reader for the given schema and package.
Method RunReader(Reader As Strix.XML.SchemaReader, SchemaLocation As %String, Package As %String, ByRef Features As %String) As %Status [ Internal ]
{
	; Get class creation times of currently existing classes in Package
	Set sc = ..GetTimes(Package, .Times)
	If 'sc Quit ..ShowError("Error determining class creation times:", sc)
	
	; Run the schema reader
	Set sc = Reader.Process(SchemaLocation, Package, .Features)
	If 'sc Quit ..ShowError("Error processing schema in {}:", sc, SchemaLocation)
	
	; Restore class creation time for classes that still exist
	Set sc = ..UpdateTimes(Package, .Times)
	If 'sc Quit ..ShowError("Error updating class creation times:", sc)
	
	; Determine the classes that were created
	If Reader.%ClassName(1) = "Strix.XML.WSDLReader" Set Reader = Reader.SchemaReader
	Set SchemaResult = ##class(%XML.Utils.SchemaResult).CreateResult(Reader, , .Features)
	
	Merge ..Classes = SchemaResult.Classes
	; Remove meaningless reader internal data
	Set k = "" For  Set k = $Order(..Classes(k)) Quit:k=""  Set ..Classes(k) = ""
	
	; Allow postprocessing the generated classes
	Set sc = ..PostprocessLoop("type")
	If 'sc Quit sc
	
	Quit $$$OK
}

/// Runs a SOAP WSDL reader
Method RunWSDLReader(Reader As Strix.XML.WSDLReader, Location As %String, Package As %String, SchemaReader As Strix.XML.SchemaReader = "") As %Status [ Internal ]
{
	; Get class creation times of currently existing classes in Package
	Set sc = ..GetTimes(Package, .Times)
	If 'sc Quit ..ShowError("Error determining class creation times:", sc)
	
	; Initialize schemareader and callback, if needed
	If SchemaReader = "" Set SchemaReader = ##class(Strix.XML.SchemaReader).%New()
	If SchemaReader.Callback = "" Set SchemaReader.Callback = $this
	
	Set sc = Reader.Process(Location, Package, , SchemaReader)
	If 'sc Quit ..ShowError("Error processing WSDL in {}:", sc, Location)
	
	; Restore class creation time for classes that still exist
	Set sc = ..UpdateTimes(Package, .Times)
	If 'sc Quit ..ShowError("Error updating class creation times:", sc)
	
	; Merge list of all classes:
	Merge ..Classes = Reader.TypeClassList
	Merge ..Classes = Reader.ClientClassList
	Merge ..Classes = Reader.BOClassList
	; Remove meaningless reader internal data
	Set k = "" For  Set k = $Order(..Classes(k)) Quit:k=""  Set ..Classes(k) = ""
	
	; Postprocessing the generated type classes.
	Kill Classes Merge Classes = Reader.TypeClassList
	Set sc = ..PostprocessLoop("type")
	If 'sc Quit sc
	
	; Postprocessing the generated client classes.
	Kill Classes Merge Classes = Reader.ClientClassList
	Set sc = ..PostprocessLoop("client")
	If 'sc Quit sc
	
	; Postprocessing the generated business operation classes.
	Kill Classes Merge Classes = Reader.BOClassList
	Set sc = ..PostprocessLoop("operation")
	If 'sc Quit sc
	
	Quit $$$OK
}

// -----

/// Helper method, optionally to be called from callback
/// OnBeforeProcessParseTree. Processes the parse tree, and removes all
/// string/date classes that are just there to host parameters; instead,
/// sets the parameters on the properties themselves.
Method ReduceDatatypeClasses() As %Status
{
	; Datatypes in the parse tree to look for, and what to replace them with
	Set Replace = $ListFromString("string,date,nonNegativeInteger,positiveInteger")
	Set ReplaceWith =  $ListFromString("%String,%Date,%xsd.nonNegativeInteger,%xsd.positiveInteger")
	
	; Loop through classes in the parse tree
	Set ckey = ""
	For  {
		Set ckey = $Order(@..ClassTree@(ckey))
		If ckey = "" Quit
		
		; Give the current node its own name
		Set Node = $Name(@..ClassTree@(ckey))
		
		; Skip classes marked temporary
		If $Get(@Node@("temporary")) Continue
		
		If @Node@("ClassType") '= "datatype" Continue
		If $Data(@Node@("DataType")), @Node@("DataType") '= "datatype" Continue
		
		; Check if this is one of the datatypes defined above
		Set Type = $Piece(@Node@("Super"), "^", 2)
		Set TypeIdx = $ListFind(Replace, Type)
		If 'TypeIdx Continue
		
		; We don't support reducing classes that are a superclass
		If $Data(@Node@("SuperBy")) Continue
		
		; Start looking for properties that use this "class"
		Set UsedByNode = $Name(@Node@("UsedBy"))
		Set UsedByNodeLen = $QLength(UsedByNode)
		
		; Loop through all "UsedBy" subnodes
		For  {
			Set UsedByNode = $Query(@UsedByNode)
			If UsedByNode = "" Quit
			If $QSubscript(UsedByNode, UsedByNodeLen) '= "UsedBy" Quit
			
			; Get the class and property indices
			Set ClassKey = $QSubscript(UsedByNode, UsedByNodeLen+1)
			Set PropKey = $QSubscript(UsedByNode, UsedByNodeLen+2)
			
			; Property may have been removed
			If '$Data(@..ClassTree@(ClassKey, "Property", PropKey)) Continue
			
			; Change the property to the replacement datatype
			Set Current = @..ClassTree@(ClassKey, "Property", PropKey, "Type")
			Set New = $List(ReplaceWith, TypeIdx)
			Set @..ClassTree@(ClassKey, "Property", PropKey, "Type") = New
			
			; Copy the parameters from the current class to the property
			Set ParmName = ""
			For  {
				Set ParmName = $Order(@Node@("Parameter", ParmName), 1, ParmValue)
				If ParmName = "" Quit
				If ParmName = "NAMESPACE" Continue
				Set @..ClassTree@(ClassKey, "Property", PropKey, "Parameter", ParmName) = ParmValue
			}
			
			; Check if the class to remove is in the CompileAfter list; if so,
			; take it our.
			Set CompileAfter = $Get(@..ClassTree@(ClassKey, "CompileAfter"))
			Set CompileAfter = ##class(Strix.Lib.String).RemoveFromList(
			    CompileAfter,, @Node@("ClassName"), .Found)
			If Found Set @..ClassTree@(ClassKey, "CompileAfter") = CompileAfter
		}
		
		; Signal to the XML processor the class is no longer needed
		Set @..ClassTree@(ckey, "Removed") = 1
		Set ..ReducedClasses = ..ReducedClasses + 1
	}
	
	Quit $$$OK
}

// -----

/// Loops through the array of class names, and calls PostProcessClass
/// for each of them
Method PostprocessLoop(Type As %String = "") As %Status [ Internal ]
{
	; If no classes are present, sc will not be set below
	Set sc = $$$OK
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(..Classes(ClassName))
		If ClassName = "" Quit
		
		Set sc = ..PostProcessClass(ClassName, Type)
		If 'sc Quit
	}
	If 'sc Quit $$$BuildStatus("Error postprocessing class {}:", sc, ClassName)
	
	Quit $$$OK
}

/// Load the creation times of all classes in Package, and return them
/// in output parameter Times. This can be used in conjunction with
/// the UpdateTimes method, to persist class creation times through
/// subsequent runs of the schemareader (which deletes the classes
/// before recreating them). This is useful to prevent source code diffs
/// showing changes when there aren't.
ClassMethod GetTimes(Package As %String, Times As %String) As %Status
{
	Set sc = $System.OBJ.GetPackageList(.Items, Package, "/includesubpackages")
	If 'sc Quit $$$BuildStatus("Error loading list of existing classes in {}:", Status, Package)
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Items(ClassName))
		If ClassName = "" Quit
		Set Time = $$$defClassKeyGet(ClassName, $$$cCLASStimecreated)
		Set Times(ClassName) = Time
	}
	Quit $$$OK
}

/// Update the class creation time for classes in Package, if this
/// information is present in the Times array. Expected to be used
/// with the output of the GetTimes method.
ClassMethod UpdateTimes(Package As %String, Times As %String) As %Status
{
	Set sc = $System.OBJ.GetPackageList(.Items, Package, "/includesubpackages")
	If 'sc Quit $$$BuildStatus("Error loading list of existing classes in {}:", Status, Package)
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Items(ClassName))
		If ClassName = "" Quit
		If '$Data(Times(ClassName)) Continue
		$$$defClassKeySet(ClassName, $$$cCLASStimecreated, Times(ClassName))
	}
	Quit $$$OK
}

/// Called in second pass through parse tree: updates CompileAfter
/// for classes that have been renamed.
Method UpdateCompileAfter() As %Status [ Private ]
{
	For i = 1:1:..RenamedClasses.Count() {
		Set Map = ..RenamedClasses.GetAt(i)
		Set From = $List(Map, 1), To = $List(Map, 2)
		
		; Check whether the current class has the renamed one in CompileAfter
		Set CompileAfter = $ListFromString(..GetCompileAfter())
		If CompileAfter = "" Continue
		Set Idx = $ListFind(CompileAfter, From)
		If 'Idx Continue
		Set $List(CompileAfter, Idx) = To
		Do ..SetCompileAfter($ListToString(CompileAfter))
	}
	
	Quit $$$OK
}

// -----

/// Callback method; if implemented in a subclass, allows to
/// process the raw parse tree before regular callbacks are
/// executed.
Method OnBeforeProcessParseTree() As %Status [ Abstract ]
{
	Set ckey = ""
	For  {
		Set ckey = $Order(@..ClassTree@(ckey))
		If ckey = "" Quit
		
	}
	Quit $$$OK
}

// -----

/// Displays an error message and/or %Status.
ClassMethod ShowError(Message As %String = "", Status As %Status = "", Args...) [ Internal ]
{
	If $Get(Args) Set Message = $$$BuildStr(Message, Args...)
	If Message '= "", Status '= "" {
		Write Message_":",!
		Do $System.Status.DisplayError(Status)
	} ElseIf Message '= "" {
		Write Message,!
	} Else {
		Do $System.Status.DisplayError(Status)
	}
	Quit 0
}

// ===== Internal =====

/// Callback from schema reader. Called after parsing is done, and
/// before any classes are created. Gets passed the name of the
/// global node that contains the classes part of the parse tree.
Method ProcessParseTree(ClassTree As %String) As %Status [ Internal ]
{
	; Save root node for other methods to use
	Set ..ClassTree = ClassTree
	
	; If a callable OnBeforeProcessParseTree method is present, call it
	If $$$comMemberKeyGet(..%ClassName(1),$$$cCLASSmethod,"OnBeforeProcessParseTree",$$$cMETHrunnable) {
		Set sc = ..OnBeforeProcessParseTree()
		If 'sc Quit $$$BuildStatus("Method OnBeforeProcessParseTree returned an error:", sc)
	}
	
	; Loop through classes to be generated
	Set ckey = ""
	For  {
		Set ckey = $Order(@ClassTree@(ckey))
		If ckey = "" Quit
		
		Set ..ClassNode = $Name(@ClassTree@(ckey))
		If $Get(@..ClassNode@("Removed")) Continue
		
		Set ..ClassName = $Get(@..ClassNode@("ClassName"))
		If ..ClassName = "" Continue
		
		Set sc = ..ProcessClassNode(..ClassName)
		If 'sc Return $$$BuildStatus("Error processing class '{}':", sc, ..ClassName)
	}
	
	; Second pass
	
	Set ckey = ""
	For  {
		Set ckey = $Order(@ClassTree@(ckey))
		If ckey = "" Quit
		
		Set ..ClassNode = $Name(@ClassTree@(ckey))
		If $Get(@..ClassNode@("Removed")) Continue
		
		Set ..ClassName = $Get(@..ClassNode@("ClassName"))
		If ..ClassName = "" Continue
		
		Set sc = ..UpdateCompileAfter()
		If 'sc Return $$$BuildStatus("Error updating CompileAfter settings", sc)
	}
	
	Quit $$$OK
}

/// Called by PostProcessParseTree for each class.
Method ProcessClassNode(Name As %String) As %Status [ Internal ]
{
	Set (..PropertyName, ..PropertyNode) = ""
	
	; Call basic callback method
	Set ShortName = $Piece(Name, ".", *)
	Set XmlName = $Get(@..ClassNode@("Parameter", "XMLNAME"), ShortName)
	
	; Handle Xml to Caché name conversion here
	Set Name = ..GetValidName($Piece(Name, ".", *), XmlName, .Changed)
	If Changed Do ..RenameClass(Name)
	
	Set sc = ..HandleClass(Name, XmlName)
	If 'sc Quit $$$BuildStatus("Error handling class '{}':", sc, ..ClassName)
	
	; Loop through properties
	For pkey = 1:1:$Get(@..ClassNode@("Property")) {
		Set ..PropertyNode = $Name(@..ClassNode@("Property", pkey))
		If '$Data(@..PropertyNode) Continue
		Set (..PropertyName, PropertyName) = @..PropertyNode@("Name")
		
		Set Type = ..Reader.TypeToClass($Get(@..PropertyNode@("Type")), .IsDatatype)
		Set XmlName = $Get(@..PropertyNode@("Parameter", "XMLNAME"), PropertyName)
		
		; Handle Xml to Caché name conversion here
		Set PropertyName = ..GetValidName(PropertyName, XmlName, .Changed)
		If Changed Do ..RenameProperty(PropertyName)
		
		Set sc = ..HandleProperty(..PropertyName, XmlName, Type, IsDatatype)
		If 'sc Return $$$BuildStatus("Error handling property {}:", sc, ..PropertyName)
	}
	Set (..PropertyName, ..PropertyNode) = ""
	
	Quit $$$OK
}

}

