<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Lib.Singleton">
<Description>
Singleton base class. Inherit from this class and add properties as needed.
This class will attempt to make sure only one instance will exist.</Description>
<Abstract>1</Abstract>
<IncludeCode>Strix</IncludeCode>
<IncludeGenerator>Strix</IncludeGenerator>
<Super>%Persistent</Super>
<TimeCreated>63865,41154.53412</TimeCreated>
<NoExtent>1</NoExtent>

<Method name="Get">
<Description>
Returns the singleton: a new one if none existed yet, otherwise the existing one.</Description>
<ClassMethod>1</ClassMethod>
<CodeMode>objectgenerator</CodeMode>
<FormalSpec>*Status:%String</FormalSpec>
<ReturnType>Strix.Lib.Singleton</ReturnType>
<Implementation><![CDATA[
	;Get new or existing instance
	Do %code.WriteLine(" Set Id = ..GetId()")
	Do %code.WriteLine(" If Id = """" {")
	Do %code.WriteLine("   Set Me = ..%New()")
	Do %code.WriteLine("   Set Status = $Select($IsObject(Me): $$$OK, 1: $Get(%objlasterror))")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("   Set Me = ..%OpenId(Id, , .Status)")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit Me")
	
	;This appears not to work, but just in case is does one day
	Set %method.ReturnType = %compiledclass.Name
	Set %compiledmethod.ReturnType = %compiledclass.Name
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="GetId">
<Description>
Returns the id of an existing instance, or an empty string if none exists.</Description>
<ClassMethod>1</ClassMethod>
<CodeMode>objectgenerator</CodeMode>
<Implementation><![CDATA[
	;Don't generate code for this class
	If %class.Abstract Quit $$$OK
	Do %code.WriteLine(" &sql(SELECT ID INTO :Id FROM "_%compiledclass.SqlQualifiedNameQ_")")
	Do %code.WriteLine(" Quit $Select(SQLCODE: """", 1: Id)")
	Quit $$$OK
]]></Implementation>
</Method>
</Class>
</Export>
