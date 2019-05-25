Include Strix

/// Base class for post-processors.
Class Strix.SCM.Processor.Base Extends %RegisteredObject
{

/// Whether the processor is meant to work on an item or on
/// a release.
Parameter HandlerType [ Constraint = ",Release,Item", Flags = ENUM ];

/// The current handler
Property Handler As Strix.SCM.Handler.Base;

/// The current project
Property Project As Strix.SCM.Project;

// =====

/// Returns a processor instance, initialized with handler and project.
ClassMethod Get(ClassName As %String, Handler As Strix.SCM.Handler.Base, Project As Strix.SCM.Project, Output Status As %Status) As Strix.SCM.Processor.Base
{
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
}

/// Release processors should override the Run method.
Method Run() As %Status [ Abstract ]
{
}

/// Item processors should provide an Export method.
Method ProcessExport(Item As %String, Export As %Stream, Output Status As %Status) As %Stream [ Abstract ]
{
}

/// Call back to handler for messages; allows the handler to filter them
/// based on e.g. verbosity.
Method Write(Text As %String)
{
	If $IsObject(..Handler) {
		Do ..Handler.HandlePostProcessorOutput(Text)
	} Else {
		Write !,Text
	}
}

}

