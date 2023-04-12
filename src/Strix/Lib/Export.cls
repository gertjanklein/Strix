/// Exports items with their dependencies to an XML file.
Class Strix.Lib.Export Extends %RegisteredObject
{

/// Export items. Uses Strix.Lib.Depends for dependency
/// checking. Items is a comma-separated list of items
/// to export. They should be suffixed with their type;
/// e.g., "Strix.Testing.pkg" or "Strix.Lib.IO.cls".
/// Exclude is a comma-separated list of items to exclude.
/// This may be useful if classes are detected through
/// an include file, when it is known that the macro's
/// they are part of won't be used.
/// Errors are displayed in the terminal. A boolean
/// indicating success is returned.
ClassMethod Export(Items As %String, Filename As %String, Exclude As %String = "") As %Boolean
{
	; Instantiate dependency checker, and turn off warnings
	Set Checker = ##class(Strix.Lib.Depends).%New()
	Set Checker.Warn = 0
	
	; Loop through items
	For i = 1:1:$Length(Items, ",") {
		Set Item = $Piece(Items, ",", i)
		
		If $ZConvert($Piece(Item, ".", *), "l") = "pkg" {
			Set Item = $Piece(Item, ".", 1, *-1)
			Set sc = Checker.CheckPackage(Item)
			
		} Else {
			Set sc = Checker.CheckItem(Item)
			
		}
		If 'sc Return ..HandleError("Error checking dependencies for {}:", sc, Item)
	}
	
	; Get items in local array
	Merge ExportItems = Checker.Dependencies
	
	; Handle exclusions, if any
	If Exclude '= "" Do ..CheckExcludes(.ExportItems, Exclude)
	
	; Export the remaining items
	Set sc = $System.OBJ.Export(.ExportItems, Filename, "-d/diffexport=1/exportselectivity=0")
	If 'sc Quit ..HandleError("Error exporting items:", sc)
	
	Quit 1
}

/// Removes items in Excludes from the Items array.
ClassMethod CheckExcludes(ByRef Items As %String, Excludes As %String)
{
	Set Excludes = $ListFromString(Excludes)
	
	; Loop through the collected items
	Set Item = ""
	For  {
		Set Item = $Order(Items(Item))
		If Item = "" Quit
		
		; Loop through the exclude list
		For i = 1:1:$ListLength(Excludes) {
			Set Exclude = $List(Excludes, i)
			
			; Exclude this item?
			If Exclude = Item {
				Kill Items(Item)
				Quit
			}
			
			; Are we to exclude a (sub-)package?
			Set Type = $Piece(Exclude, ".", *)
			If Type '= "pkg" Continue
			
			Set Package =  $Piece(Exclude, ".", 1, *-1)
			Set ItemName = $Piece(Item, ".", 1, *-1)
			
			If $Extract(ItemName, 1, $Length(Package)+1) = (Package_".") {
				; Inside package to exclude
				Kill Items(Item)
				Quit
			}
		}
	}
	
	Return
}

/// Displays an error message and %Status
ClassMethod HandleError(Message As %String, Status As %Status, Args... As %String) As %String
{
	For i = 1:1:$Get(Args) Set Message = $Replace(Message, "{}", $Get(Args(i)), , 1)
	Write Message,!
	Do $System.Status.DisplayError(Status)
	Return 0
}

}
