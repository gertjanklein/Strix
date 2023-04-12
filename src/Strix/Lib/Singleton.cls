Include Strix

IncludeGenerator Strix

/// Singleton base class. Inherit from this class and add properties as needed.
/// This class will attempt to make sure only one instance will exist.
Class Strix.Lib.Singleton Extends %Persistent [ Abstract, NoExtent ]
{

/// Returns the singleton: a new one if none existed yet, otherwise the existing one.
ClassMethod Get(Output Status As %String) As Strix.Lib.Singleton [ CodeMode = objectgenerator ]
{
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
}

/// Returns the id of an existing instance, or an empty string if none exists.
ClassMethod GetId() [ CodeMode = objectgenerator ]
{
	;Don't generate code for this class
	If %class.Abstract Quit $$$OK
	Do %code.WriteLine(" &sql(SELECT ID INTO :Id FROM "_%compiledclass.SqlQualifiedNameQ_")")
	Do %code.WriteLine(" Quit $Select(SQLCODE: """", 1: Id)")
	Quit $$$OK
}

}
