Class Strix.Lib.Collections Extends %RegisteredObject
{

/// Returns the elements present in all the input lists. These may
/// be specified as a single list of lists, or as separate parameters.
/// The items are returned in the order they appear in in the first list.
/// If objects are passed in, they are compared by Oref, i.e. they have
/// to be the same object to qualify.
ClassMethod CommonListElements(Input... As %Collection.Super) As %Collection.AbstractList
{
	; Determine how the lists were passed in
	
	If Input > 1 {
		; Lists specified separately; create container list for code below
		Set Container = ##class(%ListOfObjects).%New()
		For i = 1:1:Input Do Container.Insert(Input(i))
	} Else {
		Set Container = Input(1)
	}
	
	; Get first list from lists container
	
	Set Items = Container.GetAt(1)
	
	; Determine type and return type
	
	Set Result = ..GetCopy(Items)
	
	; Find elements present in all lists
	
	For i = 1:1:Items.Count() {
		Set Item = Items.GetAt(i)
		
		Set Present = 1
		For j = 2:1:Container.Count() {
			Set Test = Container.GetAt(j)
			If Test.%Extends("%Collection.AbstractListOfObj") {
				If Test.FindOref(Item) Continue
			} Else {
				If Test.Find(Item) Continue
			}
			Set Present = 0
			Quit
		}
		If 'Present Continue
		
		Do Result.Insert(Item)
	}
	
	Quit Result
}

/// Returns an empty copy of a collection object, of the same type as
/// the input collection, but one that can exist stand-alone. (The
/// %Collection classes can only exists as properties of an object.)
/// The collection contents are not copied unless CopyContents is true.
ClassMethod GetCopy(Input As %Collection.AbstractIterator, CopyContents As %Boolean = 0, Output Status As %Status) As %Collection.AbstractIterator
{
	Set Status = $$$OK
	Set ReturnType = ""
	
	If Input.%ClassName() = "%RelationshipObject" {
		Set ReturnType = "%ListOfObjects"
		
	} ElseIf Input.%PackageName() = "%Collection" {
		Set ReturnType = $Case(Input.%ClassName(),
		  "ListOfDT": "%ListOfDataTypes",
		  "ListOfObj": "%ListOfObjects",
		  "ArrayOfDT": "%ArrayOfDataTypes",
		  "ArrayOfObj": "%ArrayOfObjects",
		  "ListOfObjCN": "%ListOfObjectsWithClassName",
		  "ArrayOfObjCN": "%ArrayOfObjectsWithClassName",
		  "ListOfStream": "%ListOfObjects",
		  "ArrayOfStream": "%ArrayOfObjects"
		)
		
	} Else {
		; %ListOfXxx, %ArrayOfXxx
		Set ReturnType = Input.%ClassName(1)
		
	}
	
	Set Copy = $ZObjClassMethod(ReturnType, "%New")
	
	If CopyContents {
		Set Key = ""
		For  {
			Set Value = Input.GetNext(.Key)
			If Key = "" Quit
			
			; Lists should allow SetAt(..., max+1), but don't.
			If Copy.%Extends("%Collection.AbstractList") {
				Set Status = Copy.Insert(Value)
			} Else {
				Set Status = Copy.SetAt(Value, Key)
			}
		}
	}
	
	Quit Copy
}

}

