/// Helper class for timing things.
Class Strix.Lib.Timer Extends %RegisteredObject
{

/// The start time of the timer, set to $ZH-format when starting
Property StartTime As %String [ InitialExpression = {$ZHorolog}, Private ];

/// Marks, if any
Property Marks As list Of %List;

// =====

/// Constructor (%New can be used too)
/// Set %t = ##class(Strix.Lib.Timer).Get()
ClassMethod Get() As Strix.Lib.Timer
{
	Set Me = ..%New()
	Set Me.StartTime = $ZHorolog
	Quit Me
}

/// Records time passed so far; as many marks as needed can be set
/// Do %t.Mark("Here")
Method Mark(Message As %String = "")
{
	If Message = "" Set Message = "Mark "_(..Marks.Count() + 1)
	Set List = $ListBuild($ZHorolog, Message)
	Do ..Marks.Insert(List)
}

/// Clears marks and restart
/// Do %t.Reset()
Method Reset()
{
	Set ..StartTime = $ZHorolog
	Do ..Marks.Clear()
}

/// Displays results on terminal
/// Do %t.ReportToTerminal()
Method ReportToTerminal(Mark As %String = "")
{
	If Mark '= "" {
		Do ..Mark(Mark)
	} ElseIf '..Marks.Count() {
		; Make sure an endtime is present
		Do ..Mark("Total time")
	} 
	
	Set Points = ..Marks.Count()
	Set Len = $Length(Points)
	
	Set Prev = ..StartTime
	For i = 1:1:..Marks.Count() {
		Set List = ..Marks.GetAt(i)
		Set Time = $List(List, 1), Message = $ListGet(List, 2)
		
		Set DiffFromPrev = Time - Prev
		Set DiffFromFirst = Time - ..StartTime
		
		Set Nr = $Justify(i, Len)
		Write Nr_$Justify(DiffFromFirst, 8, 3)_$Justify(DiffFromPrev, 8, 3)_" "_Message,!
		
		Set Prev = Time
	}
	
	Quit
}

}

