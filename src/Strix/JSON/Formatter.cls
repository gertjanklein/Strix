/// Formats a %DynamicAbstractObject as indented JSON.
Class Strix.JSON.Formatter Extends %RegisteredObject
{

Parameter Indent = 2;

/// Entry point. Returns the JSON object converted to a formatted,
/// indented JSON string.
ClassMethod Format(JSON As %DynamicAbstractObject) As %String
{
	If JSON.%IsA("%DynamicObject") {
		Set Result = ..FormatObject(JSON)
	} ElseIf JSON.%IsA("%DynamicArray") {
		Set Result = ..FormatArray(JSON)
	}
	Quit Result
}

/// Formats a %DynamicObject. Input are the array itself and the current
/// indentation level.
ClassMethod FormatObject(Object As %DynamicObject, Indent As %String = "") As %String
{
	Set ThisIndent = Indent_$Justify("", ..#Indent)
	
	Set Result = "{"_$$$EOL
	
	#dim it As %Iterator.Object
	Set it = Object.%GetIterator()
	While it.%GetNext(.Name, .Value) {
		Set p = it.pointer, HasNext = it.%GetNext(), it.pointer = p
		Set Comma = $Select(HasNext: ",", 1:"")
		
		Set Type = Object.%GetTypeOf(Name)
		Set Result = Result_ThisIndent_""""_Name_""": "
		Set Result = Result_..FormatValue(Value, Type, ThisIndent)
		Set Result = Result_Comma_$$$EOL
	}
	Set Result = Result_Indent_"}"
	
	Quit Result
}

/// Formats a %DynamicArray. Input are the array itself and the current
/// indentation level.
ClassMethod FormatArray(Array As %DynamicArray, Indent As %String = "") As %String
{
	Set ThisIndent = Indent_$Justify("", ..#Indent)
	
	Set Result = "["
	Set PrevType = ""
	
	#dim it As %Iterator.Object
	Set it = Array.%GetIterator()
	While it.%GetNext(.Name, .Value) {
		Set Type = Array.%GetTypeOf(Name)
		
		If "object,array" [ Type, PrevType = Type {
			Set Result = Result_", "_..FormatValue(Value, Type, ThisIndent)
		} Else {
			If PrevType '= "" Set Result = Result_","
			Set Result = Result_$$$EOL_ThisIndent_..FormatValue(Value, Type, ThisIndent)
		}
		
		Set PrevType = Type
	}
	Set Result = Result_$$$EOL_Indent_"]"
	
	Quit Result
}

/// Formats a value in a %DynamicObject. Input are the value, the type,
/// and the current indent. Handles all standard %DynamicAbstractObject
/// types, does not handle Caché objects.
ClassMethod FormatValue(Value As %String, Type As %String, Indent As %String) As %String
{
	If Type = "string" Quit """"_$ZConvert(Value, "O", "JSON")_""""
	If Type = "boolean" Quit $Select(Value: "true", 1: "false")
	If Type = "number" Quit +Value
	If Type = "null" Quit "null"
	
	;Check if empty object
	If Type = "object" || (Type = "array") {
		Set HasData = Value.%GetIterator().%GetNext()
		If 'HasData Quit $Select(Type = "object": "{}", 1: "[]")
	}
	
	;Object types
	If Type = "object" Quit ..FormatObject(Value, Indent)
	If Type = "array" Quit ..FormatArray(Value, Indent)
	
	If Type = "oref" {
		;Caché object. Maybe a callback machanism can be used here. For now,
		;return the oref as string.
		Quit """"_Value_""""
	}
	
	;Fallback, we should not get here
	Quit Type_":"_$ZConvert(Value, "O", "JSON")
}

}

