Include Strix

/// Helper code for sorting objects.
Class Strix.Lib.Sorting Extends %RegisteredObject
{

// =====

/// Sorts a list of objects on one of it's properties. Sort is stable,
/// objects with the same sort key stay in the same order.
ClassMethod SortListOfObjects(List As %ListOfObjects, SortOn As %String) As %Status
{
	If List.Count() < 2 Quit $$$OK
	
	Set Status = ..ParseSortSpec(SortOn, .SortSpec)
	If 'Status Quit Status
	
	;Walk from least to most important sort field
	For FieldIndex = $ListLength(SortSpec):-1:1 {
		Set Item = $List(SortSpec, FieldIndex)
		Set Property = $List(Item, 1)
		Set Direction = $List(Item, 2)
		Set Default = $List(Item, 3)
		Set Flags = $List(Item, 4)
		
		Set Direction = $Case(Direction, "A": 1, "D": -1)
		
		;Construct array for sorting
		For i = 1:1:List.Count() {
			Set Object = List.GetAt(i)
			If Property '[ "." {
				Set Value = $ZObjProperty(Object, Property)
			} Else {
				Set Value = ..GetPropertyValue(Object, Property)
			}
			If Value = "" Set Value = Default
			If Flags [ "N" {
				;Numeric
				Set Value = +Value
			} Else {
				Set Value = " "_$ZConvert(Value, "l")
			}
			
			Set Sorted(Value, $Increment(Sorted(Value))) = Object
		}
		
		Do List.Clear()
		
		;Re-insert objects in order
		Set Value = ""
		For  {
			Set Value = $Order(Sorted(Value), Direction)
			If Value = "" Quit
			
			Set Index = ""
			For  {
				Set Index = $Order(Sorted(Value, Index), 1, Object)
				If Index = "" Quit
				Do List.Insert(Object)
			}
		}
		
		Kill Sorted
	}
	
	Quit $$$OK
}

/// Sorts the data in a %List. Sort can be ascending (default) or descending;
/// Supported flag is N for numeric.
ClassMethod SortList(Data As %List, Direction As %Integer = 1, Flags As %String = "") As %List
{
	If $ListLength(Data) < 2 Quit Data
	
	; Construct array for sorting
	For i = 1:1:$ListLength(Data) {
		Set Value = $ListGet(Data, i)
		
		If Flags [ "N" {
			;Numeric
			Set Key = +Value
		} Else {
			Set Key = " "_$ZConvert(Value, "l")
		}
		
		Set Sorted(Key, $Increment(Sorted(Key))) = Value
	}
	
	; Create sorted list
	Set Result = ""
	Set Key = ""
	For  {
		Set Key = $Order(Sorted(Key), Direction)
		If Key = "" Quit
		
		Set Index = ""
		For  {
			Set Index = $Order(Sorted(Key, Index), 1, Value)
			If Index = "" Quit
			Set Result = Result_$ListBuild(Value)
		}
	}
	
	Quit Result
}

// =====

/// Convert a string sort specification into the internal %List version, filling
/// in defaults for missing properties.
/// 
/// The full sort specification is a comma-separated list of sort specification
/// items. Items contain the following information (separated by colons):
/// - Value: the name of a property to sort on
/// - Direction: "A" (ascending, default) or "D" (descending)
/// - Default: a default value to use if the property value is empty.
/// 
/// If errors are detected in the specification, an error status is returned.
ClassMethod ParseSortSpec(SortSpec As %String, Output SortSpecList As %List) As %Status
{
	Set SortSpecList = ""
	
	Set Status = $$$OK
	For i = 1:1:$Length(SortSpec, ",") {
		Set Item = $ZStrip($Piece(SortSpec, ",", i), "<>W")
		
		Set Property = $ZStrip($Piece(Item, ":", 1), "<>W")
		Set Direction = $ZStrip($Piece(Item, ":", 2), "<>W")
		Set Default = $ZStrip($Piece(Item, ":", 3), "<>W")
		Set Flags = $ZStrip($Piece(Item, ":", 4), "<>W")
		
		If Property = "" Set Status = $$$BuildErr("Error in spec "_i_": no property.", 1) Quit
		If Direction = "" {
			Set Direction = "A"
		} ElseIf Direction '= "A", Direction '= "D" {
			Set Status = $$$BuildErr("Error in spec "_i_": invalid direction '"_Direction_"'.", 1) Quit
		}
		
		Set SortSpecList = SortSpecList_$ListBuild($ListBuild(Property, Direction, Default, Flags))
	}
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Returns the value of a dotted path, e.g. "prop.subprop".
ClassMethod GetPropertyValue(Object As %RegisteredObject, Path As %String) As %String
{
	Set Result = Object
	For i = 1:1:$Length(Path, ".") {
		Set Name = $Piece(Path, ".", i)
		Set Result = $Property(Result, Name)
	}
	Quit Result
}

}
