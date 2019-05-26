IncludeGenerator Strix

Class Strix.JSON.Adaptor Extends %Base [ Abstract, PropertyClass = Strix.JSON.PropertyParameters ]
{

/// Whether unrecognised object-type properties generate a compile-time error
/// or are simply ignored. 
Parameter SkipUnknownObjects As BOOLEAN = 0;

/// Override specifications for properties inherited from superclasses.
Parameter JSONSpec As String;

// =====

/// Instantiate a new object, and loads its properties from the %DynamicObject.
ClassMethod CreateFromJSON(Data As %DynamicObject, Spec As %String = "", Output Status As %Status) As Strix.JSON.Adaptor
{
	Set Me = ..%New()
	Set Status = Me.JSONImport(Data)
	Quit Me
}

/// Loads data into this object from the %DynamicObject passed in.
Method JSONImport(Data As %DynamicObject, Spec As %String = "") As %Status
{
	Set Status = ##class(Strix.JSON.IO).JSONImport($this, Data, Spec)
	Quit Status
}

/// Creates a %DynamicObject from the data in this object.
Method JSONExport(Sparse As %Boolean = 0, Spec As %String = "", Output Status As %Status) As %DynamicObject
{
	Set Result = ##class(Strix.JSON.IO).JSONExport($this, Sparse, Spec, .Status)
	Quit Result
}

// =====

/// Generator method that creates an array of lists with information
/// about properties to be handled in JSON I/O. Used when im-exporting
/// data from/to JSON.
ClassMethod GetPropertyInfo(Output Info) As %Integer [ CodeMode = objectgenerator ]
{
	If %compiledclass.Abstract Quit $$$OK
	
	Do %code.WriteLine($Char(9)_"Kill Info")
	Do %code.WriteLine($Char(9)_"Set Info = 0")
	
	;Get properties we must support in a list
	Set TempList = ##class(%ListOfObjects).%New()
	For i = 1:1:%compiledclass.Properties.Count() {
		#dim PropDef As %Dictionary.CompiledProperty
		Set PropDef = %compiledclass.Properties.GetAt(i)
		Set Name = PropDef.Name
		
		;Skip system properties
		If $Extract(Name) = "%" Continue
		
		;Skip properties we're told to skip
		Set JSONIO = PropDef.Parameters.GetAt("JSONIO")
		If JSONIO = "NONE" Continue
		
		Do TempList.Insert(PropDef)
	}
	
	If 'TempList.Count() Quit $$$OK
	
	Set Line = $Char(9)_";Name, JSON name, JSONIO, Type, Collection, IsDatatype, IsStream, IsRelationship, IsAdaptor, IsJSONProp"
	Do %code.WriteLine(Line)
	
	;Sort in order of appearance in the class definition
	Do ##class(Strix.Lib.Sorting).SortListOfObjects(TempList, "SequenceNumber:::N")
	
	For i = 1:1:TempList.Count() {
		Set PropDef = TempList.GetAt(i)
		
		Set Name = PropDef.Name
		Set JSONName = PropDef.Parameters.GetAt("JSONNAME")
		If JSONName = "" Set JSONName = Name, $Extract(JSONName) = $ZConvert($Extract(JSONName), "l")
		Set JSONIO = PropDef.Parameters.GetAt("JSONIO")
		
		Set Type = $$$DenormalizeClassname(PropDef.Type)
		Set IsRelationship = PropDef.Relationship
		Set Collection = PropDef.Collection
		
		;Relationship only loaded from many/children side to prevent infinite loop
		If IsRelationship, Collection = "" Continue
		
		If Type = "Strix.JSON.Property" {
			If Collection '= "" {
				;Property methods of Strix.JSON.Property not usable in lists/arrays
				Set Msg = "Class {}, property {}: collection '{}' not supported for type {}."
				Return $$$BuildStatus(Msg, , %compiledclass.Name, Name, Collection, Type)
			}
			Set IsJSONProp = 1, IsDatatype = 0, IsStream = 0, IsAdaptor = 0
			
		} ElseIf ##class(Strix.Generator.Utilities).ClassIsDataType(Type) {
			Set IsJSONProp = 0, IsDatatype = 1, IsStream = 0, IsAdaptor = 0
			
		} Else {
			Set IsJSONProp = 0, IsDatatype = 0
			
			Try { Set IsStream = $ZObjClassmethod(Type, "%Extends", "%Stream.Object") } Catch { Set IsStream = 0 }
			
			If 'IsStream {
				Try { Set IsAdaptor = $ZObjClassmethod(Type, "%Extends", "Strix.JSON.Adaptor") } Catch { Set IsAdaptor = 0 }
			}
		}
		
		Set Line = $Char(9)_"Set Info($Increment(Info)) = $lb("
		Set Line = Line_$$$quote(Name)
		Set Line = Line_","_$$$quote(JSONName)
		Set Line = Line_","_$$$quote(JSONIO)
		Set Line = Line_","_$$$quote(Type)
		Set Line = Line_","_$$$quote(Collection)
		Set Line = Line_","_+IsDatatype
		Set Line = Line_","_+IsStream
		Set Line = Line_","_+IsRelationship
		Set Line = Line_","_+IsAdaptor
		Set Line = Line_","_+IsJSONProp
		Set Line = Line_")"
		Do %code.WriteLine(Line)
	}
	
	;Return the number of properties found
	Do %code.WriteLine($Char(9)_"Quit Info")
	
	Quit $$$OK
}

}

