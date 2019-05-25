<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.SCM.Processor.Iris2Cache">
<Super>Strix.SCM.Processor.Base</Super>
<TimeCreated>65082,54599.175675</TimeCreated>

<Method name="ProcessExport">
<Description>
Replaces IRIS-specific parts of an XML export so it
can be imported in Caché.</Description>
<FormalSpec>Item:%String,Export:%Stream,*Status:%Status</FormalSpec>
<ReturnType>%Stream</ReturnType>
<Implementation><![CDATA[
	Set Status = $$$OK
	
	Set Stream = ##class(%Stream.TmpBinary).%New()
	
	Do Export.Rewind()
	While 'Export.AtEnd {
		Set Line = Export.ReadLine()
		
		If Line ? 1"<Export "1.E {
			Set Line = $Replace(Line, "generator=""IRIS""", "generator=""Cache""")
			Set Line = $Replace(Line, "version=""26""", "version=""25""")
			
		} ElseIf Line ? 1"<Type>%Storage."1.E {
			Set Line = $Replace(Line, "<Type>%Library.CacheSerialState", "%Library.CacheSerialState")
			Set Line = $Replace(Line, "<Type>%Library.CacheStorage", "%Library.CacheStorage")
			
		}
		Do Stream.WriteLine(Line)
	}
	
	Quit Stream
]]></Implementation>
</Method>
</Class>
</Export>
