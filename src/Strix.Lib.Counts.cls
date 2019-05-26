Include Strix

Class Strix.Lib.Counts Extends %RegisteredObject
{

/// The maximum number of itmes to keep
Property MaxCount As %Integer;

/// The values to record
Property Values As %String [ MultiDimensional, Private ];

/// The number of values recorded
Property ValueCount As %Integer [ Private ];

/// Which way to count
Property Strategy As %String(VALUELIST = ",nlargest,nsmallest") [ Private ];

// =====

/// Constructor: returns an nlargest counter
ClassMethod NLargest(MaxCount As %Integer = "") As Strix.Lib.Counts
{
	Quit ..%New("nlargest", MaxCount)
}

/// Constructor: returns an nsmallest counter
ClassMethod NSmallest(MaxCount As %Integer = "") As Strix.Lib.Counts
{
	Quit ..%New("nsmallest", MaxCount)
}

/// Adds a value to the counter.
Method Add(Value As %String, Name As %String = "")
{
	; If this particular value is already known we're done, we keep the first one found
	If $Data(..Values(Value)) Quit
	
	;Determine from which end of the array to drop values if we have too many
	Set Order = $Case(..Strategy, "nlargest": 1, "nsmallest": -1)
	
	; Store this value
	Set ..Values(Value) = Name, ValueCount = ..ValueCount + 1
	
	; Remove smallest values until valuecount no longer too large
	While ValueCount > ..MaxCount {
		Set Temp = $Order(..Values(""), Order)
		Kill ..Values(Temp)
		Set ValueCount = ValueCount - 1
	}
	
	Set ..ValueCount = ValueCount
	
	Quit
}

/// Clears the recorded values and optionally resets the maximum count
Method Reset(MaxCount As %Integer = "")
{
	Kill ..Values
	Set ..ValueCount = ""
	If MaxCount '= "" Set ..MaxCount = MaxCount
	Quit
}

/// Display recorded values and their names.
Method ReportToTerminal()
{
	If '..ValueCount Quit
	Set ValueColumns = $Length($Order(..Values(""), -1))
	
	Set Order = $Select(..Strategy = "nlargest": -1, 1: 1)
	Set Value = ""
	For  {
		Set Value = $Order(..Values(Value), Order, Name)
		If Value = "" Quit
		
		Write $Justify(Value, ValueColumns)_" "_Name,!
	}
	
	Quit
}

/// Method to retrieve next result, based on the provided value;
/// Can be used to retrieve results in a loop, like in %ArrayOfDataTypes.
Method GetNext(ByRef Value As %String = "") As %String
{
	Set Order = $Select(..Strategy = "nlargest": -1, 1: 1)
	Set Value = $Order(..Values(Value), Order, Data)
	If Value = "" Quit ""
	Quit Data
}

/// Method to retrieve the stored values as a list of count,name lists
Method GetList() As %List
{
	If '..ValueCount Quit ""
	
	Set Result = ""
	Set Order = $Select(..Strategy = "nlargest": -1, 1: 1)
	
	Set Value = ""
	For  {
		Set Value = $Order(..Values(Value), Order, Name)
		If Value = "" Quit
		
		Set Result = Result_$lb($lb(Value, Name))
	}
	
	Quit Result
}

// =====

Method %OnNew(Strategy As %String, MaxCount As %Integer = "") As %Status [ Private, ServerOnly = 1 ]
{
	Set ..Strategy = Strategy
	Set Status = ..StrategyIsValid(..Strategy)
	If 'Status $$$QuitErrOnNew("Strategy parameter has an invalid value", Status)
	If MaxCount Set ..MaxCount = MaxCount
	Quit $$$OK
}

}

