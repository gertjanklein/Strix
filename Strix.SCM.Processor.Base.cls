<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.SCM.Processor.Base">
<Description>
Base class for post-processors.</Description>
<IncludeCode>Strix</IncludeCode>
<Super>%RegisteredObject</Super>
<TimeCreated>64652,58901.37132</TimeCreated>

<Parameter name="HandlerType">
<Description>
Whether the processor is meant to work on an item or on
a release.</Description>
<Constraint>,Release,Item</Constraint>
<Flags>ENUM</Flags>
</Parameter>

<Property name="Handler">
<Description>
The current handler</Description>
<Type>Strix.SCM.Handler.Base</Type>
</Property>

<Property name="Project">
<Description>
The current project</Description>
<Type>Strix.SCM.Project</Type>
</Property>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="Get">
<Description>
Returns a processor instance, initialized with handler and project.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>ClassName:%String,Handler:Strix.SCM.Handler.Base,Project:Strix.SCM.Project,*Status:%Status</FormalSpec>
<ReturnType>Strix.SCM.Processor.Base</ReturnType>
<Implementation><![CDATA[
	Set Status = $$$OK
	
	#dim Processor As Strix.SCM.Processor.Base
	Set Processor = $ZObjClassMethod(ClassName, "%New")
	If Processor = "" {
		Set Status = $$$BuildStatus("Error creating instance of {}:", $Get(%objlasterror, 1), ClassName)
		Quit ""
	}
	
	If 'Processor.%IsA(..%ClassName(1)) {
		Set Status = $$$BuildStatus("Error: {} is not a subclass of {}:", , ClassName, ..%ClassName(1))
		Quit ""
	}
	
	Set Processor.Handler = Handler
	Set Processor.Project = Project
	
	Quit Processor
]]></Implementation>
</Method>

<Method name="Run">
<Description>
Release processors should override the Run method.</Description>
<Abstract>1</Abstract>
<ReturnType>%Status</ReturnType>
</Method>

<Method name="ProcessExport">
<Description>
Item processors should provide an Export method.</Description>
<Abstract>1</Abstract>
<FormalSpec>Item:%String,Export:%Stream,*Status:%Status</FormalSpec>
<ReturnType>%Stream</ReturnType>
</Method>

<Method name="Write">
<Description>
Call back to handler for messages; allows the handler to filter them
based on e.g. verbosity.</Description>
<FormalSpec>Text:%String</FormalSpec>
<Implementation><![CDATA[
	If $IsObject(..Handler) {
		Do ..Handler.HandlePostProcessorOutput(Text)
	} Else {
		Write !,Text
	}
]]></Implementation>
</Method>
</Class>
</Export>
