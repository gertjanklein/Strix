/// Helper code for retrieving existing Ensemble data (responses,
/// lookup tables) and storing it in XData blocks for use in tests.
/// 
/// This class is self-contained, so it can easily be copied to
/// another IRIS instance, to collect data there.
Class Strix.Testing.TestData [ Abstract ]
{

/// Saves the Ensemble message body of a request/response class to an XData block.
/// Do ##class(Strix.Testing.TestData).CopyMessage("","","")
ClassMethod CopyMessage(MessageId As %String, ClassName As %String = "", XDataName As %String = "") As %String
{
	; Open the Ensemble message
	Set Msg = ##class(Ens.MessageBody).%OpenId(MessageId, , .sc)
	If 'sc Return ..ShowError("Error opening Ensemble message with id {}:", sc, MessageId)
	
	; Default name for class and XData in case none provided
	If ClassName = "" Set ClassName = "TestData.M"_MessageId
	If XDataName = "" Set XDataName = Msg.%ClassName(0)_MessageId
	
	; Open/create the class to save the XData to
	If '..GetClass(ClassName, .Class) Return ""
	
	#dim XData As %Dictionary.XDataDefinition
	Set XData = ..GetInCollection(Class.XDatas, XDataName, 1, .sc)
	If 'sc Return ..ShowError("Error getting XData {}/{}:", sc, ClassName, XDataName)
	
	; Clear stream in case it already existed
	Set sc = XData.Data.Clear()
	If 'sc Return ..ShowError("Error clearing existing XData {}/{}:", sc, ClassName, XDataName)
	
	; Export to XData block
	Set sc = Msg.XMLExportToStream(XData.Data,,",indent()")
	If 'sc Return ..ShowError("Error exporting message to XData {}/{}:", sc, ClassName, XDataName)
	
	; Save updated class
	Set sc = Class.%Save()
	If 'sc Return ..ShowError("Error saving updated dictionary for {}:", sc, ClassName)
	
	Write "Done.",!
	
	Return ""
}

/// Copies all messages in a given session. Can optionally exclude
/// requests or responses.
/// Do ##class(Strix.Testing.TestData).CopySession("","")
ClassMethod CopySession(SessionId As %String, ClassName As %String = "", Requests As %Boolean = 1, Responses As %Boolean = 1)
{
	; Default classname if none provided
	If ClassName = "" Set ClassName = "TestData.S"_SessionId
	
	; Create/open class definition
	#dim Class As %Dictionary.ClassDefinition
	If '..GetClass(ClassName, .Class) Return ""
	Set IsNew = Class.%Id() = ""
	
	Set Query = "SELECT MessageBodyId, Type FROM Ens.MessageHeader WHERE SessionId = ?"
	Set Query = Query_" ORDER BY MessageBodyId"
	
	#dim rs As %SQL.StatementResult
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, SessionId)
	While rs.%Next(.sc) {
		; Skip messages we're not interested in
		If rs.Type = 1, 'Requests Continue
		If rs.Type = 2, 'Responses Continue
		If rs.Type '= 1, rs.Type '= 2 Continue
		
		; Skip messages no longer present (possibly purged)
		Set Id = rs.MessageBodyId
		If '##class(Ens.MessageBody).%ExistsId(Id) Continue
		
		; Open message object
		Set Msg = ##class(Ens.MessageBody).%OpenId(Id, , .sc)
		If 'sc Return ..ShowError("Error opening Ensemble message with id {}:", sc, Id)
		
		; Show what's happening
		Write $Case(rs.Type, 1: "Request", 2: "Response"), " ", Msg.%ClassName(), " ", Id,!
		
		; XData name is last part of classname plus message id
		Set XDataName = Msg.%ClassName(0)_Id
		
		; Get/create XData
		#dim XData As %Dictionary.XDataDefinition
		Set XData = ..GetInCollection(Class.XDatas, XDataName, 1, .sc)
		If 'sc Return ..ShowError("Error getting XData {}/{}:", sc, ClassName, XDataName)
		If IsNew Set XData.SequenceNumber = $Increment(IsNew)
		
		; Clear stream in case it already existed
		Set sc = XData.Data.Clear()
		If 'sc Return ..ShowError("Error clearing existing XData {}/{}:", sc, ClassName, XDataName)
		
		; Export to XData block
		Set sc = Msg.XMLExportToStream(XData.Data,,",indent()")
		If 'sc Return ..ShowError("Error exporting message to XData {}/{}:", sc, ClassName, XDataName)
		
	}
	If 'sc Return ..ShowError("Error creating/iterating resultset:", sc)
	
	; Actually copied something?
	If $IsObject(Class) {
		; Save updated class
		Set sc = Class.%Save()
		If 'sc Return ..ShowError("Error saving updated dictionary for {}:", sc, ClassName)
		Write "Done.",!
	
	} Else {
		Write "Nothing found to copy.",!
		
	}
	
	Return ""
}

/// Copies the contents of one or more lookup tables to XData block(s)
/// in the specified class. Table names are separated by a comma.
/// Do ##class(Strix.Testing.TestData).CopyLUT("","")
ClassMethod CopyLUT(Tables As %String, ClassName As %String = "") As %String
{
	; Default classname if none provided
	If ClassName = "" Set ClassName = "TestData.LUT"
	
	If '..GetClass(ClassName, .Class) Return ""
	
	For i = 1:1:$Length(Tables, ",") {
		Set Table = $Piece(Tables, ",", i)
		
		#dim XData As %Dictionary.XDataDefinition
		Set XData = ..GetInCollection(Class.XDatas, Table, 1, .sc)
		If 'sc Return ..ShowError("Error getting XData for {}/{}:", sc, ClassName, Table)
		
		; Clear stream in case it already existed
		Set sc = XData.Data.Clear()
		If 'sc Return ..ShowError("Error clearing existing XData {}/{}:", sc, ClassName, Table)
		
		Set sc = ##class(Ens.Util.LookupTable).%Export(XData.Data, Table)
		If 'sc Return ..ShowError("Error exporting data to {}/{}:", sc, ClassName, Table)
	}
	
	Set sc = Class.%Save()
	If 'sc Return ..ShowError("Error saving updated dictionary for {}:", sc, ClassName)
	
	Write "Done.",!
	
	Return ""
}

// ===== Internal helpers =====

/// Opens or creates a class definition
ClassMethod GetClass(ClassName As %String, Output Class As %Dictionary.ClassDefinition) As %Boolean [ Private ]
{
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ClassName) {
		Set Class = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .sc)
		If 'sc Return ..ShowError("Error opening dictionary for {}:", sc, ClassName)
		
	} Else {
		Set Class = ##class(%Dictionary.ClassDefinition).%New(ClassName, 25)
		Set Class.Abstract = 1
		
	}
	
	Return 1
}

/// Returns an item, specified by name, from a relationship collection
/// (such as CompiledClass:Properties, etc.).
ClassMethod GetInCollection(Collection As %RelationshipObject, Name As %String, Create As %Boolean = 0, Output Status As %Status) As %RegisteredObject [ Private ]
{
	Set Status = $$$OK
	
	Set Found = 0
	Set Key = ""
	For  {
		Set Object = Collection.GetNext(.Key)
		If Key = "" Quit
		If Object.Name = Name Set Found = 1 Quit
	}
	If Found Quit Object
	
	If 'Create Quit ""
	
	Set Object = $ZObjClassMethod(Collection.ElementType, "%New")
	Set Object.Name = Name
	Set Status = Collection.Insert(Object)
	
	Quit Object
}

/// Displays an error message and/or %Status. Returns an arbitrary
/// (but false) value so this method can be used in a quit/return
/// expression.
ClassMethod ShowError(Message As %String = "", Status As %Status = "", Args... As %String) As %String [ Private ]
{
	; Replace message template placeholders, if any
	For i = 1:1:$Get(Args) {
		Set Message = $Replace(Message, "{}", $Get(Args(i)), , 1)
	}
	
	If Message '= "", Status '= "" {
		Write Message_":",!
		Do $System.Status.DisplayError(Status)
	} ElseIf Message '= "" {
		Write Message,!
	} Else {
		Do $System.Status.DisplayError(Status)
	}
	
	Return ""
}

}
