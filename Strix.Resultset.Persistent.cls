<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Resultset.Persistent">
<Description>
Wrapper for %ScrollableResultSet, intended for pagination of webservice
results. Works by wrapping the system resultset (delegation).</Description>
<IncludeCode>Strix</IncludeCode>
<Super>%Persistent</Super>
<TimeCreated>63699,40874.34797</TimeCreated>

<Property name="PageSize">
<Description>
Paging support: the number of rows in a page</Description>
<Type>%Integer</Type>
<Parameter name="MINVAL" value="1"/>
</Property>

<Property name="CurrentPage">
<Description>
Paging support: the current page number</Description>
<Type>%Integer</Type>
<Parameter name="MINVAL" value="1"/>
</Property>

<Property name="CurrentIndex">
<Description>
Paging support: the current row index (within the current page)</Description>
<Type>%Integer</Type>
<Parameter name="MINVAL" value="1"/>
</Property>

<Property name="SessionKey">
<Description>
SessionKey can contain the LoginID of a user.</Description>
<Type>%String</Type>
</Property>

<Property name="DateTimeCreated">
<Description>
Date/time this object was created</Description>
<Type>%TimeStamp</Type>
<InitialExpression>$ZDateTime($ZUtil(188), 3, 1)</InitialExpression>
</Property>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Property name="EmbeddedResultset">
<Description>
The actual embedded scrollable resultset. This is such a weird object it
can't be saved as a property; instead we have to save the id *and* save
the object...</Description>
<Type>%Library.ScrollableResultSet</Type>
<Transient>1</Transient>
</Property>

<Property name="EmbeddedResultsetId">
<Description>
The Id of the embedded %ScrollableResultSet</Description>
<Type>%String</Type>
</Property>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="GetResultset">
<Description>
Creates and returns a new or existing resultset object. QueryName specifies the
name of the class query. For dynamic SQL, use %DynamicQuery:SQL and specify the
query string as the first query parameter.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Request:Strix.Resultset.Request,*Resultset:Strix.Resultset.Persistent,QueryName:%String,QueryParameters...</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="GetResultsetInfo">
<Description>
Returns basic information about an existing resultset.</Description>
<ReturnType>Strix.Resultset.Info</ReturnType>
<Implementation><![CDATA[
	Set Info = ##class(Strix.Resultset.Info).%New()
	Set Info.ResultsetID = ..%Id()
	
	If ..PageSize '= "", ..CurrentPage '= "" {
		Set Info.FirstItem = (..CurrentPage - 1) * ..PageSize + 1
	}
	
	Set Info.ItemCount = ..EmbeddedResultset.Count()
	
	Quit Info
]]></Implementation>
</Method>

<Method name="SetupResultset">
<Description>
Sets up the scrollable resultset</Description>
<FormalSpec>QueryName:%String,QueryParameters...:%String</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Paging code

]]></Content>
</UDLText>

<Method name="Move">
<Description>
Move to a different page; How can be first, previous, next, last, page.
If How is page, PageNr specifies the page to move to. Returns a boolean
indicating whether the page index was actually changed.</Description>
<FormalSpec>How:%String,PageNr:%Integer</FormalSpec>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="Next">
<Description>
Moves to the next row. If paging is set up, navigates within the current page,
otherwise it delegates to %ResultSet's Next(). Returns false if there is
no next row.</Description>
<FormalSpec>*Status:%Status=$$$OK</FormalSpec>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="SetPageSize">
<Description>
Sets the page size; resets CurrentPage and CurrentIndex.</Description>
<FormalSpec>PageSize:%Integer</FormalSpec>
<Implementation><![CDATA[
	If PageSize < 1 Quit
	Set ..PageSize = PageSize
	Set ..CurrentPage = ""
	Set ..CurrentIndex = ""
	Quit
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Delegation

]]></Content>
</UDLText>

<Method name="Get">
<CodeMode>expression</CodeMode>
<FormalSpec>name:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.Get(name)
]]></Implementation>
</Method>

<Method name="GetData">
<CodeMode>expression</CodeMode>
<FormalSpec>n:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetData(n)
]]></Implementation>
</Method>

<Method name="GetObject">
<CodeMode>expression</CodeMode>
<ReturnType>%RegisteredObject</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetObject()
]]></Implementation>
</Method>

<Method name="GetColumnCount">
<CodeMode>expression</CodeMode>
<ReturnType>%Integer</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetColumnCount()
]]></Implementation>
</Method>

<Method name="GetColumnName">
<CodeMode>expression</CodeMode>
<FormalSpec>n:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetColumnName(n)
]]></Implementation>
</Method>

<Method name="GetColumnExtInfo">
<CodeMode>expression</CodeMode>
<FormalSpec>n:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetColumnExtInfo(n)
]]></Implementation>
</Method>

<Method name="GetColumnHeader">
<CodeMode>expression</CodeMode>
<FormalSpec>n:%Integer</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetColumnHeader(n)
]]></Implementation>
</Method>

<Method name="GetColumnType">
<CodeMode>expression</CodeMode>
<FormalSpec>n:%Integer</FormalSpec>
<ReturnType>%Integer</ReturnType>
<Implementation><![CDATA[..EmbeddedResultset.GetColumnType(n)
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Queries

]]></Content>
</UDLText>

<Query name="ForSessionKey">
<Description>
Returns the ID of all resultsets for a given session key. If SessionKey
is empty, all resultsets are returned.</Description>
<Type>%SQLQuery</Type>
<FormalSpec>SessionKey:%String</FormalSpec>
<SqlQuery>SELECT %ID
  FROM Persistent
 WHERE ISNULL(SessionKey, '') = ISNULL(:SessionKey, '')</SqlQuery>
<Parameter name="CONTAINID" value="1"/>
</Query>

<UDLText name="T">
<Content><![CDATA[
// ===== Cleanup

]]></Content>
</UDLText>

<Method name="DeleteOnSessionKey">
<Description>
Deletes all persisted resultsets with a specific SessionKey.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>SessionKey:%String</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== Object callbacks

]]></Content>
</UDLText>

<Method name="%OnAddToSaveSet">
<Description>
Called when the object is about to be saved</Description>
<FormalSpec>depth:%Integer=3,insert:%Integer=0,callcount:%Integer=0</FormalSpec>
<Private>1</Private>
<ReturnType>%Status</ReturnType>
<ServerOnly>1</ServerOnly>
<Implementation><![CDATA[
	Set Status = ..EmbeddedResultset.%Save()
	If 'Status Quit $$$BuildErr("Error saving embedded %ScrollableResulSet", Status)
	Set ..EmbeddedResultsetId = ..EmbeddedResultset.%Id()
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="%OnOpen">
<Description>
Called when object is being opened</Description>
<Private>1</Private>
<ReturnType>%Status</ReturnType>
<ServerOnly>1</ServerOnly>
<Implementation><![CDATA[
	If ..EmbeddedResultsetId = "" Quit $$$OK
	Set ..EmbeddedResultset = ##class(%ScrollableResultSet).%OpenId(..EmbeddedResultsetId, , .Status)
	If 'Status Quit Status
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="%OnDelete">
<Description>
Called when object is deleted</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>oid:%ObjectIdentity</FormalSpec>
<Private>1</Private>
<ReturnType>%Status</ReturnType>
<ServerOnly>1</ServerOnly>
<Implementation><![CDATA[
	Set id = $lg(oid)
	Set EmbeddedId = ##class(Strix.Resultset.Persistent).EmbeddedResultsetIdGetStored(id)
	If EmbeddedId = "" Quit $$$OK
	
	Set Status = ##class(%ScrollableResultSet).%DeleteId(EmbeddedId)
	If 'Status Quit $$$BuildErr("Error deleting embedded resultset '"_EmbeddedId_"':", Status)
	
	Quit $$$OK
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// ===== SQL callbacks

]]></Content>
</UDLText>

<Trigger name="OnDelete">
<Description>
If a resultset is deleted via SQL, make sure the %ScrollableResultSet
data is removed as well.</Description>
<Code>	Set Id = {EmbeddedResultsetId*O}
	If Id '= "" Do ##class(%ScrollableResultSet).%DeleteId(Id)</Code>
<Event>DELETE</Event>
<Time>AFTER</Time>
</Trigger>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Storage name="Default">
<Type>%Library.CacheStorage</Type>
<DataLocation>^Strix.Resultset.PersistentD</DataLocation>
<DefaultData>PersistentDefaultData</DefaultData>
<IdLocation>^Strix.Resultset.PersistentD</IdLocation>
<IndexLocation>^Strix.Resultset.PersistentI</IndexLocation>
<StreamLocation>^Strix.Resultset.PersistentS</StreamLocation>
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
</Storage>
</Class>
</Export>
