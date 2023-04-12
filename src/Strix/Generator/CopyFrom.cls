Class Strix.Generator.CopyFrom [ Abstract ]
{

/// Copies properties (with the same name) from another object
/// into this one. The other object doesn't have to have the same
/// class; properties are matched by name.
Method CopyFrom(Other As %RegisteredObject) [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Set Cls = Other.%ClassName(1)")
	Set key = ""
	For  {
		#dim PropDef As %Dictionary.PropertyDefinition
		Set PropDef = %class.Properties.GetNext(.key)
		If key = "" Quit
		
		If PropDef.Private Continue
		If PropDef.ReadOnly Continue
		If PropDef.Relationship Continue
		
		Set Name = PropDef.Name
		If $Extract(Name) = "%" Continue
		
		If PropDef.Collection = "" {
			Do %code.WriteLine(" If $$$comMemberDefined(Cls, $$$cCLASSproperty, """_Name_""") Set .."_Name_" = Other."_Name)
		} Else {
			Do %code.WriteLine(" If $$$comMemberDefined(Cls, $$$cCLASSproperty, """_Name_""") {")
			Do %code.WriteLine("   Do .."_Name_".Clear() Set k = """"")
			Do %code.WriteLine("   For { Set val = Other."_Name_".GetNext(.k) Quit:k=""""  Do .."_Name_".SetAt(val, k) }")
			Do %code.WriteLine(" }")
		}
	}
	
	Quit $$$OK
}

}
