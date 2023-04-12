Include Strix

/// Various XML-related helper methods
Class Strix.XML.Util Extends %RegisteredObject
{

/// Creates objects for the classes specified in ClassNames, from the
/// XML in Input (a string, stream or filename), and returns them
/// in Objects.
/// The names of the classes to look for should be specified as either
/// a comma-separated string or a $list. The XML name is taken from
/// the XMLNAME class parameter.
/// The Objects collection will be created if it doesn't exists; if it
/// does, it will not be cleared.
ClassMethod ObjectsFromXML(Input, ClassNames As %String, Output Objects As %Collection.AbstractListOfObj = "") As %Status
{
	; Only create collection if not passed in
	If '$IsObject(Objects) || 'Objects.%IsA("%Collection.AbstractListOfObj") {
		Set Objects = ##class(%ListOfObjects).%New()
	}

	Set Reader = ##class(%XML.Reader).%New()

	;== Determine input type

	If $IsObject(Input) {
		;Assume stream
		Set Status = Reader.OpenStream(Input)
		If 'Status Quit $$$BuildErr("Error opening input as stream:", Status)

	} ElseIf ##class(%File).Exists(Input) {
		;Valid filename is unlikely to be intended as XML
		Set Status = Reader.OpenFile(Input)
		If 'Status Quit $$$BuildErr("Error opening input as file:", Status)

	} Else {
		;No stream, not a file: must be XML in string
		Set Status = Reader.OpenString(Input)
		If 'Status Quit $$$BuildErr("Error opening input as string:", Status)

	}

	;== Process list of class names

	; Convert to list if it isn't already
	If '$ListValid(ClassNames) Set ClassNames = $ListFromString(ClassNames)
	For i = 1:1:$ListLength(ClassNames) {
		Set ClassName = $ZStrip($List(ClassNames, i), "<>W")
		If ClassName = "" Continue

		Set XMLName = $$$GetClassParameter(ClassName, "XMLNAME")
		If XMLName = "" Set XMLName = $Piece(ClassName, ".", $Length(ClassName, "."))

		Do Reader.Correlate(XMLName, ClassName)
	}

	;== Get objects

	While Reader.Next(.Object, .Status) {
		Do Objects.Insert(Object)
	}
	If 'Status Quit $$$BuildErr("Error correlating object:", Status)

	Quit $$$OK
}

/// Outputs the schema for the given class (and dependent classes) to
/// a stream.
ClassMethod GetClassSchema(ClassName As %String, Output Output As %Stream.Object = "") As %Status
{
	If '$IsObject(Output) {
		Set Output = ##class(%Stream.TmpBinary).%New()
	}

	Set Schema = ##class(%XML.Schema).%New()

	Set Namespace = "http://tempuri.org/"
	Set Schema.DefaultNamespace = Namespace

	Set Writer = ##class(%XML.Writer).%New()
	Set Writer.Indent = 1
	Do Writer.AddSchemaNamespace()
	Do Writer.AddNamespace(Namespace, "o")

	Set Status = Writer.OutputToStream(Output)
	If 'Status Quit $$$BuildStatus("Error setting output stream:", Status)

	Set Status = Schema.AddSchemaType(ClassName)
	If 'Status Quit $$$BuildStatus("Error adding schema type:", Status)

	Set Status = Writer.DocumentNode(Schema.GetSchema(Namespace))
	If 'Status Quit $$$BuildStatus("Error writing schema:", Status)

	Quit $$$OK
}

/// Retrieves a property from an XML %XML.Document, either from an element
/// or from an attribute. Can be used from a %XML.Adaptor:XMLNew() override
/// to get the value of the id element or attribute.
ClassMethod GetPropertyFromDoc(Document As %XML.Document, NodeId As %Integer, Property As %String, IsAttribute As %Boolean = 0) As %String
{
	Set Value = ""
	
	#dim Node As %XML.Node	
	Set Node = Document.GetNode(NodeId)
	
	If IsAttribute {
		If Node.AttributeDefined(Property) Do Node.GetAttribute(Property, , .Value)
		Quit Value
	}
	
	If 'Node.MoveToFirstChild() Quit Value
	Do {
		If Node.NodeData = Property Do Node.GetText(.Value) Quit
	} While Node.MoveToNextSibling()
	
	Quit Value
}

}
