/// Removes the last newline from an export. This is needed
/// for compatibility with exports created by the VS Code
/// objectscript plugin, which contains a bug with that effect.
Class Strix.SCM.Processor.VSCodeCompat Extends Strix.SCM.Processor.Base
{

/// Removes the final newline of the export stream.
Method ProcessExport(Item As %String, Export As %Stream, Output Status As %Status) As %Stream
{
	Set Status = ..RemoveLastLine(Export)
	Quit Export
}

ClassMethod RemoveLastLine(Stream As %Stream.Object) As %Status
{
	If Stream.Size '< $$$MaxStringLength Quit $$$BuildStatus("Stream too large.")
	Set Data = Stream.Read(Stream.Size-2, .sc)
	If 'sc Quit sc
	Set Last = Stream.Read(, .sc)
	If 'sc Quit sc
	If Last = Stream.LineTerminator Set sc = Stream.Write(Data)
	If 'sc Quit sc
	Quit $$$OK
}

}
