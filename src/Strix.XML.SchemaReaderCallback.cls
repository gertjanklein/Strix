Include Strix

Class Strix.XML.SchemaReaderCallback Extends %RegisteredObject
{

/// The reader we receive the callback from
Property Reader As Strix.XML.SchemaReader;

// -----

/// Name of the currently handled class
Property ClassName As %String;

/// Global node containing the class information
Property ClassNode As %String;

/// Name of the currently handled property
Property PropertyName As %String;

/// Global node containing the property information
Property PropertyNode As %String;

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
Method PostProcessClass(ClassName As %String) As %Status
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
	Set SchemaResult = ##class(%XML.Utils.SchemaResult).CreateResult(Reader, , .Features)
	Merge Classes = SchemaResult.Classes
	
	; Allow postprocessing the generated classes
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Classes(ClassName))
		If ClassName = "" Quit
		
		Set sc = ..PostProcessClass(ClassName)
		If 'sc Quit
	}
	If 'sc Quit $$$BuildStatus("Error postprocessing class {}:", sc, ClassName)
	
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
	
	; Allow postprocessing the generated classes. This does not include the
	; service/operation/message classes (if any).
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Reader.TypeClassList(ClassName))
		If ClassName = "" Quit
		
		Set sc = ..PostProcessClass(ClassName)
		If 'sc Quit
	}
	If 'sc Quit $$$BuildStatus("Error postprocessing class {}:", sc, ClassName)
	
	Quit $$$OK
}

// -----

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

