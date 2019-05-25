<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.Counts">
<IncludeCode>Strix</IncludeCode>
<Super>%RegisteredObject</Super>
<TimeCreated>63857,71004.238777</TimeCreated>

<Property name="MaxCount">
<Description>
The maximum number of itmes to keep</Description>
<Type>%Integer</Type>
</Property>

<Property name="Values">
<Description>
The values to record</Description>
<Type>%String</Type>
<MultiDimensional>1</MultiDimensional>
<Private>1</Private>
</Property>

<Property name="ValueCount">
<Description>
The number of values recorded</Description>
<Type>%Integer</Type>
<Private>1</Private>
</Property>

<Property name="Strategy">
<Description>
Which way to count</Description>
<Type>%String</Type>
<Private>1</Private>
<Parameter name="VALUELIST" value=",nlargest,nsmallest"/>
</Property>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="NLargest">
<Description>
Constructor: returns an nlargest counter</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>MaxCount:%Integer=""</FormalSpec>
<ReturnType>Strix.Lib.Counts</ReturnType>
<Implementation><![CDATA[	Quit ..%New("nlargest", MaxCount)
]]></Implementation>
</Method>

<Method name="NSmallest">
<Description>
Constructor: returns an nsmallest counter</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>MaxCount:%Integer=""</FormalSpec>
<ReturnType>Strix.Lib.Counts</ReturnType>
<Implementation><![CDATA[	Quit ..%New("nsmallest", MaxCount)
]]></Implementation>
</Method>

<Method name="Add">
<Description>
Adds a value to the counter.</Description>
<FormalSpec>Value:%String,Name:%String=""</FormalSpec>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="Reset">
<Description>
Clears the recorded values and optionally resets the maximum count</Description>
<FormalSpec>MaxCount:%Integer=""</FormalSpec>
<Implementation><![CDATA[
	Kill ..Values
	Set ..ValueCount = ""
	If MaxCount '= "" Set ..MaxCount = MaxCount
	Quit
]]></Implementation>
</Method>

<Method name="ReportToTerminal">
<Description>
Display recorded values and their names.</Description>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="GetNext">
<Description>
Method to retrieve next result, based on the provided value;
Can be used to retrieve results in a loop, like in %ArrayOfDataTypes.</Description>
<FormalSpec><![CDATA[&Value:%String=""]]></FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Order = $Select(..Strategy = "nlargest": -1, 1: 1)
	Set Value = $Order(..Values(Value), Order, Data)
	If Value = "" Quit ""
	Quit Data
]]></Implementation>
</Method>

<Method name="GetList">
<Description>
Method to retrieve the stored values as a list of count,name lists</Description>
<ReturnType>%List</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="%OnNew">
<FormalSpec>Strategy:%String,MaxCount:%Integer=""</FormalSpec>
<Private>1</Private>
<ReturnType>%Status</ReturnType>
<ServerOnly>1</ServerOnly>
<Implementation><![CDATA[
	Set ..Strategy = Strategy
	Set Status = ..StrategyIsValid(..Strategy)
	If 'Status $$$QuitErrOnNew("Strategy parameter has an invalid value", Status)
	If MaxCount Set ..MaxCount = MaxCount
	Quit $$$OK
]]></Implementation>
</Method>
</Class>
</Export>
