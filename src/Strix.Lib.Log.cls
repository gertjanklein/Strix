Include Strix

/// Simple logger class
Class Strix.Lib.Log Extends %Persistent
{

/// When the event occurred
Property When As %TimeStamp [ InitialExpression = {$ZDateTime($ZUtil(188), 3, 1, 3)} ];

/// The type of event: Debug, Info, Error
Property Type As %String;

/// Where the event occurred (e.g. classname:methodname)
Property Location As %String(MAXLEN = 256);

/// %Status, if known
Property Status As %Status;

/// Information about the event
Property Message As %String(MAXLEN = 4096);

// =====

/// Logs an event of type Error
ClassMethod LogError(Location As %String, Message As %String = "", Status As %Status = "") As %Status
{
	Set Me = ..%New()
	
	Set Me.Type = "Error"
	Set Me.Location = Location
	Set Me.Message = Message
	Set Me.Status = Status
	
	Set sc = Me.%Save()
	If 'sc Do Me.HandleSaveFailure(sc)
	
	;Return a status combining mesage and status
	If $Quit Quit $$$BuildErr(Message, Status)
	
	Quit
}

/// Logs a trapped error (e.g., from a $ZTrap trap)
ClassMethod LogTrappedError(Location As %String, Message As %String = "") As %Status
{
	Set Me = ..%New()
	
	Set Me.Type = "Error"
	Set Me.Location = Location
	Set Me.Message = Message_" "_$ZError
	
	Set sc = Me.%Save()
	If 'sc Do Me.HandleSaveFailure(sc)
	
	;Return a status containing the message
	If $Quit Quit $$$BuildErr(Message, 1)
	
	Quit
}

/// Logs an assert failure
ClassMethod LogAssertionError(Location As %String, Condition As %String, Message As %String = "") As %Status
{
	Set Me = ..%New()
	
	Set Me.Type = "Assert"
	Set Me.Location = Location
	Set Me.Message = Condition
	If Message '= "" Set Me.Message = Me.Message_" ("_Message_")"
	
	Set sc = Me.%Save()
	If 'sc Do Me.HandleSaveFailure(sc)
	
	;Return a status containing the message
	If $Quit Quit $$$BuildErr(Message, 1)
	
	Quit
}

/// Logs an event of type Info
ClassMethod LogInfo(Location As %String, Message As %String)
{
	Set Me = ..%New()
	
	Set Me.Type = "Info"
	Set Me.Location = Location
	Set Me.Message = Message
	
	Set sc = Me.%Save()
	If 'sc Do Me.HandleSaveFailure(sc)
	
	Quit
}

/// Logs an event of type Debug
ClassMethod LogDebug(Location As %String, Message As %String)
{
	Set Me = ..%New()
	
	Set Me.Type = "Debug"
	Set Me.Location = Location
	Set Me.Message = Message
	
	Set sc = Me.%Save()
	If 'sc Do Me.HandleSaveFailure(sc)
	
	Quit
}

/// Fallback method to store info about a failed save in a global
/// for later examination.
Method HandleSaveFailure(Status As %Status) [ CodeMode = objectgenerator ]
{
	#define Write(%s) Do %code.WriteLine($Char(9)_%s)
	
	$$$Write("Set Index = $Increment(^LogErrors)")
	
	Set Key = ""
	For  {
		#dim PropDef As %Dictionary.CompiledProperty
		Set PropDef = %compiledclass.Properties.GetNext(.Key)
		If Key = "" Quit
		
		If PropDef.Private Continue
		Set Name = PropDef.Name
		If $Extract(Name) = "%" Continue
		
		$$$Write("Set ^LogErrors(Index, ""d"", """_Name_""") = .."_Name)
	}
	
	$$$Write("Set ^LogErrors(Index, ""s"") = Status")
	
	Quit $$$OK
}

Storage Default
{
<Data name="LogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>When</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Location</Value>
</Value>
<Value name="5">
<Value>Status</Value>
</Value>
<Value name="6">
<Value>Message</Value>
</Value>
</Data>
<DataLocation>^Strix.Lib.LogD</DataLocation>
<DefaultData>LogDefaultData</DefaultData>
<IdLocation>^Strix.Lib.LogD</IdLocation>
<IndexLocation>^Strix.Lib.LogI</IndexLocation>
<StreamLocation>^Strix.Lib.LogS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

