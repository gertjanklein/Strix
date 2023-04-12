Class Strix.SCM.Processor.Iris2Cache Extends Strix.SCM.Processor.Base
{

/// Replaces IRIS-specific parts of an XML export so it
/// can be imported in Caché.
Method ProcessExport(Item As %String, Export As %Stream, Output Status As %Status) As %Stream
{
	Set Status = $$$OK
	
	Set Stream = ##class(%Stream.TmpBinary).%New()
	
	Do Export.Rewind()
	While 'Export.AtEnd {
		Set Line = Export.ReadLine()
		
		If Line ? 1"<Export "1.E {
			Set Line = $Replace(Line, "generator=""IRIS""", "generator=""Cache""")
			Set Line = $Replace(Line, "version=""26""", "version=""25""")
			
		} ElseIf Line ? 1"<Type>%Storage."1.E {
			Set Line = $Replace(Line, "<Type>%Storage.Serial", "<Type>%Library.CacheSerialState")
			Set Line = $Replace(Line, "<Type>%Storage.Persistent", "<Type>%Library.CacheStorage")
			
		}
		Do Stream.WriteLine(Line)
	}
	
	Quit Stream
}

}
