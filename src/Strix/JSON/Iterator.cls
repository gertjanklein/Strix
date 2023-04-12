/// Iterator over dynamic objects with additional helper methods.
Class Strix.JSON.Iterator Extends %RegisteredObject
{

Property Object As %DynamicAbstractObject;

Property Iterator As %Iterator.Array;

// =====

ClassMethod GetIterator(Object As %DynamicAbstractObject) As Strix.JSON.Iterator
{
	Set Me = ..%New()
	Set Me.Object = Object
	Set Me.Iterator = Object.%GetIterator()
	Quit Me
}

// =====

/// GetNext mirrors the iterators %GetNext method, but additionally
/// outputs the type of the value
Method GetNext(Output Key, Output Value, Output Type As %String) As %Boolean
{
	Set HasValue = ..Iterator.%GetNext(.Key, .Value)
	If 'HasValue Set Type = "" Quit 0
	Set Type = ..Object.%GetTypeOf(Key)
	Quit 1
}

Method GetPrevious(Output Key, Output Value, Output Type As %String) As %Boolean
{
	If ..Iterator.pointer < 1 Set (Key, Value) = "" Quit 0
	
	;Find a position before the previous item
	Set SavedPointer = ..Iterator.pointer
	Set Found = 0, Pointer = ..Iterator.pointer - 1
	For  {
		Set Pointer = Pointer - 1
		Set ..Iterator.pointer = Pointer
		Do ..Iterator.%GetNext(.Key, .Value)
		If ..Iterator.pointer '= SavedPointer {
			;We've found the previous element
			Set Type = ..Object.%GetTypeOf(Key)
			Set Found = 1
			Quit
		}
		;If no elements left to try, quit
		If ..Iterator.pointer < 0 Quit
	}
	
	If 'Found Set (Key, Value) = "", Type = "unassigned" Quit 0
	
	Quit 1
}

/// Resets the iterator to its initial state
Method Reset()
{
	Set ..Iterator.pointer = -1
}

Method IsFirst() As %Boolean [ CodeMode = expression ]
{
..PeekPrevious()
}

Method IsLast() As %Boolean [ CodeMode = expression ]
{
..PeekNext()
}

/// Gets the next key/value/type for the given (array or object) iterator,
/// without changing the current state.
/// Returns false if no next value is present.
Method PeekNext(Output Key, Output Value, Output Type) As %Boolean
{
	Set SavedPointer = ..Iterator.pointer
	Set HasValue = ..Iterator.%GetNext(.Key, .Value)
	Set ..Iterator.pointer = SavedPointer
	Set Type = $Select(HasValue: ..Object.%GetTypeOf(Key), 1: "unassigned")
	Quit HasValue
}

/// Gets the previous key/value/type for the given (array or object) iterator,
/// without changing the current state.
/// Returns false if no next value is present.
Method PeekPrevious(Output Key, Output Value, Output Type) As %Boolean
{
	If ..Iterator.pointer < 1 Set (Key, Value) = "", Type = "unassigned" Quit 0
	
	;Find a position before the previous item
	Set SavedPointer = ..Iterator.pointer
	Set Found = 0, Pointer = ..Iterator.pointer - 1
	For  {
		Set Pointer = Pointer - 1
		Set ..Iterator.pointer = Pointer
		Do ..Iterator.%GetNext(.Key, .Value)
		If ..Iterator.pointer '= SavedPointer {
			;We've found the previous element
			Set Type = ..Object.%GetTypeOf(Key)
			Set Found = 1
			Quit
		}
		;If no elements left to try, quit
		If ..Iterator.pointer < 0 Quit
	}
	Set ..Iterator.pointer = SavedPointer
	
	If 'Found Set (Key, Value) = "", Type = "unassigned" Quit 0
	
	Quit 1
}

}
