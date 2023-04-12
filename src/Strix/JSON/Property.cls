Include Strix

IncludeGenerator Strix

Class Strix.JSON.Property Extends %DataType
{

/// Specifies what conversion to perform on values, if any.
/// . JSON: convert JSON strings to %DynamicObject (on set and open)
/// . Str: Convert %DynamicObject to their equivalent string (on set)
/// . (empty): Do no conversion.
/// Properties with Conversion set to JSON will reconvert stored
/// values to a %DynamicObject when opening an existing object.
/// %DynamicArray is treated the same as %DynamicObject.
Parameter Conversion As STRING [ Constraint = ",JSON,Str", Flags = ENUMEDIT ];

// =====

/// Value must either be a %Dynamic[Object|Array], or a valid JSON string.
ClassMethod IsValid(%val) As %Status
{
	If %val = "" Quit $$$OK
	If $IsObject(%val) {
		If %val.%IsA("%DynamicAbstractObject") Quit $$$OK
		Quit $$$BuildStatus("Unrecognised object type {}.",, %val.%ClassName(1))
	}
	Try {
		Do ##class(%DynamicAbstractObject).%FromJSON(%val)
	} Catch {
		Return $$$BuildStatus("String not valid JSON.")
	}
	Quit $$$OK
}

/// Setter implements type conversion, if needed.
Method Set(%val) As %Status [ CodeMode = objectgenerator, NoContext ]
{
	Set Name = %property
	
	; If name is empty we're compiling this class
	If Name = "" Quit $$$OK
	
	; If no conversion requested, we don't need a setter
	Set Conversion = $Get(%parameter("Conversion"))
	If (Conversion = "") Quit $$$OK
	
	; Custom setter is only possible on non-collection properties
	If $$$comMemberKeyGet(%class.Name, $$$cCLASSproperty, Name, $$$cPROPruntimetype) [ "%Collection" {
		Set Msg = "Property {}: conversion ({}) not possible for collection properties."
		Quit $$$BuildStatus(Msg, , Name, Conversion)
	}
	
	If Conversion = "Str" {
		; Convert to string
		Set Value = "$s($isobject(%val):%val.%ToJSON(),1:%val)"
		
	} ElseIf Conversion = "JSON" {
		; Convert to JSON object, if possible
		Set Value = "$s(%val="""":"""",""[{""[$e(%val):##class(%DynamicAbstractObject).%FromJSON(%val),1:%val)"
		
	} Else {
		Quit $$$BuildStatus("Property {}: unknown Conversion '{}'.", , Name, Conversion)
		
	}
	
	Do %code.WriteLine($Char(9)_"Set i%"_Name_"="_Value)
	Do %code.WriteLine($Char(9)_"Quit $$$OK")
	
	Quit $$$OK
}

// =====

/// Returns the property value as a string, even if it is a %DynamicObject
/// (or -Array).
Method AsString() As %String
{
	If '$IsObject(%val) Quit %val
	Quit %val.%ToJSON()
}

/// Returns the property value as a %DynamicObject (or -Array),
/// if possible, even if it is a string.
Method AsObject() As %DynamicAbstractObject
{
	If $IsObject(%val) Quit %val
	If %val = "" Quit ""
	Quit ##class(%DynamicAbstractObject).%FromJSON(%val)
}

// =====

/// Converts %DynamicObject to the equivalent JSON when storing.
ClassMethod LogicalToStorage(%val) As %String
{
	If '$IsObject(%val) Quit %val
	Quit %val.%ToJSON()
}

/// Reload value from disk: convert value back to %DynamicObject
/// (or -Array), if it was one.
ClassMethod StorageToLogical(%val) As %String [ CodeMode = objectgenerator, NoContext ]
{
	Set Name = %property
	
	; If name is empty we're compiling this class
	If Name = "" Quit $$$OK
	
	If %parameter("Conversion")="JSON" {
		; Convert to JSON object, if possible
		Set Value = "$s(%val="""":"""",""[{""[$e(%val):##class(%DynamicAbstractObject).%FromJSON(%val),1:%val)"
		
	} Else {
		; Don't change anything here
		Set Value = "%val"
		
	}
	
	Do %code.WriteLine($Char(9)_"Quit "_Value)
	
	Quit $$$OK
}

}
