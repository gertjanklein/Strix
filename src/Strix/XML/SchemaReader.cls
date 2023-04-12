Include Strix

IncludeGenerator Strix

/// Schema reader that adds a callback after parsing is done,
/// but before the classes are created.
Class Strix.XML.SchemaReader Extends %XML.Utils.SchemaReader
{

/// Object to receive a callback when the schema is processed, but
/// before the classes are created. Allows altering
Property Callback As Strix.XML.SchemaReaderCallback;

/// Setter that provides a back reference to the schema reader
/// (this object) to the callback object.
Method CallbackSet(Callback As Strix.XML.SchemaReaderCallback) As %Status
{
	Set i%Callback = Callback
	If $IsObject(Callback) Set Callback.Reader = $this
	Quit $$$OK
}

// =====

/// Processes XSD present in a stream, by creating a temporary file for it.
Method ProcessStream(Stream As %Stream.Object, Package As %String, ByRef Features As %String) As %Status
{
	Set FileName = ##class(%File).TempFilename("xsd")
	Set File = ##class(%FileCharacterStream).%New()
	Set File.TranslateTable = "UTF8"
	Set sc = File.LinkToFile(FileName)
	If 'sc Quit $$$BuildStatus("Error linking to temporary file {}:", sc, FileName)
	Set sc = File.CopyFromAndSave(Stream)
	If 'sc Quit $$$BuildStatus("Error copying data to temporary file {}:", sc, FileName)
	Set sc = ..Process(FileName, .Package, .Features)
	Do ##class(%File).Delete(FileName)
	Quit sc
}

// =====

/// Overridden method, used to call callback directly after the
/// schema is parsed.
Method ParseSchema(filename As %String, url As %String = "") As %Status [ Internal ]
{
	Set sc = ##super(.filename, .url)
	If 'sc Quit sc
	
	; Run entry method on callback object, if present
	If $IsObject(..Callback) {
		Set sc = ..Callback.ProcessParseTree($Name($$$ClassTreeRoot))
		If 'sc Quit sc
	}
	
	Quit $$$OK
}

}
