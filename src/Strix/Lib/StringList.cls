Include Strix

/// Creates a list-like string without binary characters.
Class Strix.Lib.StringList Extends %RegisteredObject
{

/// Create a stringlist from the input; each parameter will be a list item.
ClassMethod Create(Items... As %String) As %String
{
	Set Result = ""
	
	For i = 1:1:$Get(Items) {
		If '$Data(Items(i)) {
			;Null item
			Set Result = Result_"0n"
			Continue
			
		} ElseIf '$Length(Items(i)) {
			;Empty item
			Set Result = Result_"0s"
			Continue
			
		}
		
		Set Item = ..Escape(Items(i), .HasEscapes)
		Set Type = $Select(HasEscapes: "e", 1: "s")
		
		Set Result = Result_$Length(Item)_Type_Item
	}
	
	Quit Result
}

/// Converts a stringlist to a sequential array of items. The top node
/// specifies the total number of items; null items are not present
/// in the array (but are in the count). The array is suitable to
/// use in method calls using the triple-dot syntax. Example:
/// Set StringList = ##class(Strix.Lib.StringList).Create("testing","one","two")
/// Do ##class(Strix.Lib.StringList).Explode(StringList, .Items)
/// Do ##class(SomeClass).SomeMethod(Items...)
/// Which is equivalent to:
/// Do ##class(SomeClass).SomeMethod("testing","one","two")
ClassMethod Explode(StringList As %String, ByRef Items As %String) As %Status
{
	Set Status = ..GetIndices(StringList, .Indices)
	If 'Status Quit Status
	
	Set Items = Indices
	
	For i = 1:1:Indices {
		Set ItemInfo = Indices(i)
		
		Set TypeStart = $List(ItemInfo, 2)
		Set Type = $Extract(StringList, TypeStart)
		If Type = "n" Continue
		
		Set ContentStart = $List(ItemInfo, 3)
		Set ContentEnd = $List(ItemInfo, 4)
		Set Content = $Extract(StringList, ContentStart, ContentEnd)
		
		If Type = "e" Set Content = ..Unescape(Content)
		
		Set Items(i) = Content
	}
	
	Quit $$$OK
}

/// Checks whether the input is a valid StringList
ClassMethod Check(StringList As %String, Output Status As %Status) As %Boolean
{
	Set Status = ..GetIndices(StringList)
	Quit Status = $$$OK
}

/// Returns a specific item from a stringlist. If a null item is requested,
/// the value in Default is returned.
ClassMethod GetItem(StringList As %String, Index As %Integer, Default As %String = "") As %String
{
	Set Status = ..GetIndices(StringList, .Indices)
	If 'Status Quit ""
	
	If Index > Indices Quit ""
	If Index < 1 Quit ""
	
	Set ItemInfo = Indices(Index)
	
	Set TypeStart = $List(ItemInfo, 2)
	Set Type = $Extract(StringList, TypeStart)
	If Type = "n" Quit Default
	
	Set ContentStart = $List(ItemInfo, 3)
	Set ContentEnd = $List(ItemInfo, 4)
	Set Content = $Extract(StringList, ContentStart, ContentEnd)
	
	If Type = "e" Set Content = ..Unescape(Content)
	
	Quit Content
}

/// Returns one or more items from a stringlist as stringlist.
ClassMethod GetSubList(StringList As %String, From As %Integer, To As %Integer = "") As %String
{
	Set Status = ..GetIndices(StringList, .Indices)
	If 'Status Quit ""
	
	If From > Indices Quit ""
	If From < 1 Quit ""
	
	If To {
		If To > Indices Set To = Indices
		If To < 1 Quit ""
	} Else {
		Set To = From
	}
	
	Set FromInfo = Indices(From)
	Set ItemStart = $List(FromInfo, 1)
	
	If To = From {
		Set ItemEnd = $List(FromInfo, 4)
	} Else {
		Set ToInfo = Indices(To)
		Set ItemEnd = $List(ToInfo, 4)
	}
	
	Set SubList = $Extract(StringList, ItemStart, ItemEnd)
	
	Quit SubList
}

/// Returns the length (number of items) in stringlist
ClassMethod GetLength(StringList As %String) As %Integer
{
	Set Status = ..GetIndices(StringList, .Indices)
	If 'Status Quit ""
	Quit Indices
}

// =====

/// Converts a Caché %List to a StringList.
ClassMethod FromList(Input As %List) As %String
{
	If Input = "" Quit ""
	
	;Create parameters array
	Set Parameters = $ListLength(Input)
	
	Set Ptr = 0, ItemNr = 0
	While $ListNext(Input, Ptr, Value) {
		Set ItemNr = ItemNr + 1
		If '$Data(Value) Continue
		
		Set Parameters(ItemNr) = Value
	}
	
	;Convert to stringlist
	Set Result = ..Create(Parameters...)
	
	Quit Result
}

/// Converts a StringList to a Caché %List.
ClassMethod ToList(StringList As %String) As %List
{
	If StringList = "" Quit ""
	
	Set Result = ""
	Do ..GetIndices(StringList, .Indices)
	For i = 1:1:Indices {
		Set ItemInfo = Indices(i)
		Set TypeStart = $List(ItemInfo, 2)
		Set ContentStart = $List(ItemInfo, 3)
		Set ContentEnd = $List(ItemInfo, 4)
		
		Set Type = $Extract(StringList, TypeStart)
		
		If Type = "n" Set Result = Result_$ListBuild() Continue
		
		Set Content = $Extract(StringList, ContentStart, ContentEnd)
		If Type = "e" Set Content = ..Unescape(Content)
		
		Set Result = Result_$ListBuild(Content)
	}
	
	Quit Result
}

// =====

/// Retuns an array with various indices of the items in a stringlist.
ClassMethod GetIndices(StringList As %String, Output Indices) As %Status
{
	Set Indices = 0
	If StringList = "" Quit $$$OK
	
	Set Status = $$$OK
	Set Index = 1
	For ItemNr = 1:1 {
		;Length of item content
		Set ContentLen = +$Extract(StringList, Index, Index + 10)
		
		;Length of sting containing content size
		Set SizeStringLen = $Length(ContentLen)
		
		;Validity check:
		If ContentLen '= $Extract(StringList, Index, Index + SizeStringLen - 1) {
			Set Status = $$$BuildErr("Invalid stringlist (invalid content length); item "_ItemNr_", index "_Index_".", 1)
			Quit
		}
		
		;Total lenght of item: size string + type + content
		Set ItemLen = SizeStringLen + 1 + ContentLen
		
		;Offset of start of item, offset of type character, offset of content, offset of last content character
		Set Indices($Increment(Indices)) = $ListBuild(Index, Index + SizeStringLen, Index + SizeStringLen + 1, Index + ItemLen - 1)
		
		;If this was the last item quit from the loop
		If Index + ItemLen - 1 = $Length(StringList) Quit
		
		;Validity check: make sure expected item content is there
		If Index + ItemLen > $Length(StringList) {
			Set Status = $$$BuildErr("Invalid stringlist (content truncated); item "_ItemNr_", index "_Index_".", 1)
			Quit
		}
		
		Set Index = Index + ItemLen
	}
	
	Quit Status
}

// =====

/// Escapes control characters in the input string, by replacing them
/// with "\nn", where nn is the hex code of the control character.
ClassMethod Escape(Input As %String, Output HasEscapes As %Boolean) As %String
{
	Set Result = "", HasEscapes = 0
	
	;If input does not contain control characters we don't have to escape
	If Input '? .E1.C.E Quit Input
	
	For i = 1:1:$Length(Input) {
		Set Char = $Extract(Input, i)
		If Char '? 1(1C,1"\") {
			Set Result = Result_Char
		} Else {
			Set HasEscapes = 1
			Set Ord = $Ascii(Char)
			Set Ord = $Translate($Justify($ZHex(Ord), 2), " ", "0")
			Set Result = Result_"\"_Ord
		}
		
	}
	
	Quit Result
}

/// Converts an escaped string back into input format
ClassMethod Unescape(Input As %String) As %String
{
	Set Result = ""
	
	Set Index = 0, PrevIndex = 1
	For  {
		Set Index = $Find(Input, "\", Index)
		
		If Index > 2 || 'Index {
			Set End = $Select(Index: Index - 2, 1: $Length(Input))
			Set Result = Result_$Extract(Input, PrevIndex, End)
		}
		
		If 'Index Quit
		
		Set Ord = $Extract(Input, Index, Index + 1)
		Set Char = $Char($ZHex(Ord))
		Set Result = Result_Char
		
		Set Index = Index + 1
		Set PrevIndex = Index + 1
	}
	
	Quit Result
}

}
