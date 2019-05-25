Include Strix

/// Wrapper for %ScrollableResultSet, intended for pagination of webservice
/// results. Works by wrapping the system resultset (delegation).
Class Strix.Resultset.Persistent Extends %Persistent
{

/// Paging support: the number of rows in a page
Property PageSize As %Integer(MINVAL = 1);

/// Paging support: the current page number
Property CurrentPage As %Integer(MINVAL = 1);

/// Paging support: the current row index (within the current page)
Property CurrentIndex As %Integer(MINVAL = 1);

/// SessionKey can contain the LoginID of a user.
Property SessionKey As %String;

/// Date/time this object was created
Property DateTimeCreated As %TimeStamp [ InitialExpression = {$ZDateTime($ZUtil(188), 3, 1)} ];

// =====

/// The actual embedded scrollable resultset. This is such a weird object it
/// can't be saved as a property; instead we have to save the id *and* save
/// the object...
Property EmbeddedResultset As %Library.ScrollableResultSet [ Transient ];

/// The Id of the embedded %ScrollableResultSet
Property EmbeddedResultsetId As %String;

// =====

/// Creates and returns a new or existing resultset object. QueryName specifies the
/// name of the class query. For dynamic SQL, use %DynamicQuery:SQL and specify the
/// query string as the first query parameter.
ClassMethod GetResultset(Request As Strix.Resultset.Request, Output Resultset As Strix.Resultset.Persistent, QueryName As %String, QueryParameters...) As %Status
{
	Set ResultsetId = Request.ResultsetID
	
	If ResultsetId '= "" {
		;Open existing resultset
		Set Resultset = ..%OpenId(ResultsetId, , .Status)
		If 'Status Quit $$$BuildErr("Error opening resultset '"_ResultsetId_"':", Status)
		
		;Sanity check
		If Request.SessionKey '= "", Request.SessionKey '= Resultset.SessionKey {
			Quit $$$BuildErr("Request from '"_Request.SessionKey_"' for resultset '"_ResultsetId_"' owned by '"_Resultset.SessionKey_"'.", 1)
		}
		
	} Else {
		;Create new resultset object
		Set Resultset = ..%New()
		Set Resultset.SessionKey = Request.SessionKey
		
	}
	
	If +Request.PageNumber = 0, Resultset.EmbeddedResultset '= "" {
		;Existing query but needs to re-run. %ScrollableResultSet doesn't support this,
		;so clear current one.
		If Resultset.EmbeddedResultset.%Id() '= "" Do Resultset.EmbeddedResultset.%DeleteId(Resultset.EmbeddedResultset.%Id())
		Set Resultset.EmbeddedResultset = "", Resultset.EmbeddedResultsetId = ""
	}
	
	If Resultset.EmbeddedResultset = "" {
		;Execute the query
		Set Status = Resultset.SetupResultset(QueryName, QueryParameters...)
		If 'Status Quit Status
	}
	
	;If no page specified, default to 1
	If +Request.PageNumber = 0 Set Request.PageNumber = 1
	
	;Set resultset page size and requested page number, if paging set up
	If Request.PageSize {
		Do Resultset.SetPageSize(Request.PageSize)
		Do Resultset.Move("page", Request.PageNumber)
		Set Resultset.EmbeddedResultset.CurrRow = Request.PageSize * (Request.PageNumber - 1) + 1
	}
	
	;Save the resultset
	Set Status = Resultset.%Save()
	If 'Status Quit $$$BuildErr("Error saving resultset:", Status)
	
	Quit $$$OK
}

/// Returns basic information about an existing resultset.
Method GetResultsetInfo() As Strix.Resultset.Info
{
	Set Info = ##class(Strix.Resultset.Info).%New()
	Set Info.ResultsetID = ..%Id()
	
	If ..PageSize '= "", ..CurrentPage '= "" {
		Set Info.FirstItem = (..CurrentPage - 1) * ..PageSize + 1
	}
	
	Set Info.ItemCount = ..EmbeddedResultset.Count()
	
	Quit Info
}

/// Sets up the scrollable resultset
Method SetupResultset(QueryName As %String, QueryParameters... As %String) As %Status
{
	;Use apatched version of %ScrollableResultSet to make OpenObject() work.
	Set ..EmbeddedResultset = ##class(Strix.Patches.ScrollableResultSet).%New(QueryName)
	If '$IsObject(..EmbeddedResultset) Quit $$$BuildErr("Error creating resultset for query '"_QueryName_"'", $Get(%objlasterror))
	
	If QueryName = "%DynamicQuery:SQL" {
		;Dynamic query; first parameter is the query itself.
		Set Query = $Get(QueryParameters(1))
		
		;Remove the query from the parameters
		Set QueryParameters = $Get(QueryParameters, 1) - 1
		For i = 1:1:QueryParameters {
			If $Data(QueryParameters(i + 1)) {
				Set QueryParameters(i) = QueryParameters(i + 1)
			} Else {
				Kill QueryParameters(i)
			}
		}
		Kill QueryParameters(QueryParameters + 1)
		
		;Prepare the query:
		Set Status = ..EmbeddedResultset.Prepare(Query)
		If 'Status Quit $$$BuildErr("Error preparing query:", Status)
	}
	
	;Execute:
	Set Status = ..EmbeddedResultset.Execute(QueryParameters...)
	If 'Status Quit $$$BuildErr("Error executing query:", Status)
	
	;Save:
	Set Status = ..EmbeddedResultset.%Save()
	If 'Status Quit $$$BuildErr("Error saving embedded resultset:", Status)
	
	Quit $$$OK
}

// ===== Paging code

/// Move to a different page; How can be first, previous, next, last, page.
/// If How is page, PageNr specifies the page to move to. Returns a boolean
/// indicating whether the page index was actually changed.
Method Move(How As %String, PageNr As %Integer) As %Boolean
{
	Set How = $ZConvert(How, "l")
	
	;No paging: original resultset delivers everything
	If ..PageSize = "" Quit 0
	
	If How = "first" {
		If ..CurrentPage = 1 Quit 0
		Set ..CurrentPage = 1
		Set ..CurrentIndex = ""
		Quit 1
	}
	
	If How = "previous" {
		If ..CurrentPage '> 1 Quit 0
		Set ..CurrentPage = ..CurrentPage - 1
		Set ..CurrentIndex = ""
		Quit 1
	}
	
	Set Max = ..EmbeddedResultset.Count()
	Set MaxPage = 1
	
	If ..PageSize > 0 Set MaxPage = Max - 1 \ ..PageSize + 1
	
	If How = "next" {
		If ..CurrentPage '< MaxPage Quit 0
		Set ..CurrentPage = ..CurrentPage + 1
		Set ..CurrentIndex = ""
		Quit 1
	}
	
	If How = "last" {
		If ..CurrentPage = MaxPage Quit 0
		Set ..CurrentPage = MaxPage
		Set ..CurrentIndex = ""
		Quit 1
	}
	
	If How = "page" {
		If (PageNr < 1) || (PageNr > MaxPage) Quit 0
		Set ..CurrentPage = PageNr
		Set ..CurrentIndex = ""
		Quit 1
	}
	
	;Make this crash so the programming error is noticed
	ZTrap "ARG" ;Invalid argument for How
	
	Quit 0
}

/// Moves to the next row. If paging is set up, navigates within the current page,
/// otherwise it delegates to %ResultSet's Next(). Returns false if there is
/// no next row.
Method Next(Output Status As %Status = {$$$OK}) As %Boolean
{
	;If paging not set up, delegate up
	If ..PageSize = "" Quit ..EmbeddedResultset.Next(.Status)
	
	If ..CurrentIndex = "" {
		;Not yet started on this page
		Set CurrentIndex = 1
		
	} ElseIf ..CurrentIndex < ..PageSize {
		;Within page, go to next row
		Set CurrentIndex = ..CurrentIndex + 1
		
	} Else {
		; End of page reached, return false
		Set ..CurrentIndex = ""
		Quit 0
	}
	
	Set RowNr = ..PageSize * (..CurrentPage - 1) + CurrentIndex
	If RowNr > ..EmbeddedResultset.Count() Set ..CurrentIndex = "" Quit 0
	
	;Set %ScrollableResultSet current row
	Set ..EmbeddedResultset.CurrRow = RowNr
	
	;...and save current index
	Set ..CurrentIndex = CurrentIndex
	
	Quit 1
}

/// Sets the page size; resets CurrentPage and CurrentIndex.
Method SetPageSize(PageSize As %Integer)
{
	If PageSize < 1 Quit
	Set ..PageSize = PageSize
	Set ..CurrentPage = ""
	Set ..CurrentIndex = ""
	Quit
}

// ===== Delegation

Method Get(name As %String) As %String [ CodeMode = expression ]
{
..EmbeddedResultset.Get(name)
}

Method GetData(n As %Integer) As %String [ CodeMode = expression ]
{
..EmbeddedResultset.GetData(n)
}

Method GetObject() As %RegisteredObject [ CodeMode = expression ]
{
..EmbeddedResultset.GetObject()
}

Method GetColumnCount() As %Integer [ CodeMode = expression ]
{
..EmbeddedResultset.GetColumnCount()
}

Method GetColumnName(n As %Integer) As %String [ CodeMode = expression ]
{
..EmbeddedResultset.GetColumnName(n)
}

Method GetColumnExtInfo(n As %Integer) As %String [ CodeMode = expression ]
{
..EmbeddedResultset.GetColumnExtInfo(n)
}

Method GetColumnHeader(n As %Integer) As %String [ CodeMode = expression ]
{
..EmbeddedResultset.GetColumnHeader(n)
}

Method GetColumnType(n As %Integer) As %Integer [ CodeMode = expression ]
{
..EmbeddedResultset.GetColumnType(n)
}

// ===== Queries

/// Returns the ID of all resultsets for a given session key. If SessionKey
/// is empty, all resultsets are returned.
Query ForSessionKey(SessionKey As %String) As %SQLQuery(CONTAINID = 1)
{
SELECT %ID
  FROM Persistent
 WHERE ISNULL(SessionKey, '') = ISNULL(:SessionKey, '')
}

// ===== Cleanup

/// Deletes all persisted resultsets with a specific SessionKey.
ClassMethod DeleteOnSessionKey(SessionKey As %String) As %Status
{
	Set rs = ##class(%ResultSet).%New("Viva.Utilities.PersistentResultset:ForSessionKey")
	If '$IsObject(rs) Quit $$$BuildErr("Error creating resultset:", $Get(%objlasterror))
	
	Set Status = rs.Execute(SessionKey)
	If 'Status Quit $$$BuildErr("Error executing resultset:", Status)
	
	Set Result = $$$OK
	While rs.Next() {
		Set Id = rs.Get("ID")
		Set Status = ..%DeleteId(Id)
		If 'Status Set Result = $System.Status.AppendStatus(Result, $$$BuildErr("Error deleting Id '"_Id_"':", Status))
	}
	If 'Result Quit $$$BuildErr("Errors found deleting data:", Result)
	
	Quit $$$OK
}

// ===== Object callbacks

/// Called when the object is about to be saved
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Set Status = ..EmbeddedResultset.%Save()
	If 'Status Quit $$$BuildErr("Error saving embedded %ScrollableResulSet", Status)
	Set ..EmbeddedResultsetId = ..EmbeddedResultset.%Id()
	Quit $$$OK
}

/// Called when object is being opened
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	If ..EmbeddedResultsetId = "" Quit $$$OK
	Set ..EmbeddedResultset = ##class(%ScrollableResultSet).%OpenId(..EmbeddedResultsetId, , .Status)
	If 'Status Quit Status
	Quit $$$OK
}

/// Called when object is deleted
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set id = $lg(oid)
	Set EmbeddedId = ##class(Strix.Resultset.Persistent).EmbeddedResultsetIdGetStored(id)
	If EmbeddedId = "" Quit $$$OK
	
	Set Status = ##class(%ScrollableResultSet).%DeleteId(EmbeddedId)
	If 'Status Quit $$$BuildErr("Error deleting embedded resultset '"_EmbeddedId_"':", Status)
	
	Quit $$$OK
}

// ===== SQL callbacks

/// If a resultset is deleted via SQL, make sure the %ScrollableResultSet
/// data is removed as well.
Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	Set Id = {EmbeddedResultsetId*O}
	If Id '= "" Do ##class(%ScrollableResultSet).%DeleteId(Id)
}

// =====

Storage Default
{
<Data name="PersistentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PageSize</Value>
</Value>
<Value name="3">
<Value>CurrentPage</Value>
</Value>
<Value name="4">
<Value>CurrentIndex</Value>
</Value>
<Value name="5">
<Value>SessionKey</Value>
</Value>
<Value name="6">
<Value>DateTimeCreated</Value>
</Value>
<Value name="7">
<Value>EmbeddedResultsetId</Value>
</Value>
</Data>
<DataLocation>^Strix.Resultset.PersistentD</DataLocation>
<DefaultData>PersistentDefaultData</DefaultData>
<IdLocation>^Strix.Resultset.PersistentD</IdLocation>
<IndexLocation>^Strix.Resultset.PersistentI</IndexLocation>
<StreamLocation>^Strix.Resultset.PersistentS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

