Include (Ensemble, Strix)

/// Support code for Ensemble-related tests. Placed in a separate
/// class so the other support code can be used on non-Ensemble
/// systems (this class will not compile there).
Class Strix.Testing.EnsSupport Extends %RegisteredObject
{

/// Ensures an Ensemble production with the given name is running.
/// If another production is currently running, it is stopped first.
/// Makes sure that the messages that would normally be written to
/// the terminal are silenced.
ClassMethod EnsureProduction(Name As %String) As %Status
{
	New %QUIET
	Set %QUIET = 1
	
	Set sc = ##class(Ens.Director).GetProductionStatus(.Current, .State)
	If 'sc Quit $$$BuildStatus("Error determining production status:", sc)
	
	If Current = Name, State = $$$eProductionStateRunning Quit $$$OK
	
	If State '= $$$eProductionStateStopped {
		If State '= $$$eProductionStateRunning Quit $$$BuildStatus("Unexpected production status {}.",, State)
		Set sc = ##class(Ens.Director).StopProduction()
		If 'sc Quit $$$BuildStatus("Error stopping current production ({}):", sc, Current)
	}
	If Current = "" Set Current = $Get(^Ens.Configuration("csp","LastProduction"))
	
	Set sc = ##class(Ens.Director).StartProduction(Name)
	If 'sc Quit $$$BuildStatus("Error starting production '{}':", sc, Name)
	
	; Remember previous production for restoring later
	Set ^||Strix.Testing.EnsSupport("PrevProduction") = Current
	
	Quit $$$OK
}

/// Stops the currently running production. Makes sure that the
/// messages that would normally be written to the terminal
/// are silenced.
ClassMethod StopProduction(Timeout As %Numeric, Force As %Boolean) As %Status
{
	New %QUIET
	Set %QUIET = 1
	
	Set sc = ##class(Ens.Director).StopProduction(.Timeout, .Force)
	If 'sc Quit sc
	
	; Restore previous production, if saved
	Set Prev = $Get(^||Strix.Testing.EnsSupport("PrevProduction"))
	If Prev '= "" Set ^Ens.Configuration("csp","LastProduction") = Prev
	
	Quit $$$OK
}

/// Returns an EnsLib.Testing.Service instance to use for sending
/// a single test request. Also outputs the session id that will
/// be used for that request; this is used to save assertions run
/// in out-of-process Ensemble components.
ClassMethod GetTestService(Output Service As EnsLib.Testing.Service, Output SessionId As %String, Source As %String = "") As %Status
{
	Set sc = ##class(Ens.Director).CreateBusinessService("EnsLib.Testing.Service", .Service)
	If 'sc Quit sc
	
	Set sc = Service.ForceSessionId()
	If 'sc Quit $$$BuildStatus("Error initializing session id:", sc)
	Set SessionId = Service.%SessionId
	Do ##class(Strix.Testing.Runner).SetSource(SessionId, Source)
	
	Quit $$$OK
}

/// Returns whether any of the messages in a given session has an
/// error status. If so, output parameters return information about
/// the first one found: the message header id, a string describing
/// the message, and the error status.
ClassMethod CheckErrorStatus(SessionId As %String, Output Id As %String, Output MessageDesc As %String, Output Status As %Status) As %Boolean
{
	Set (Id, Type, TargetConfigName, Status) = ""
	
	Set Query = ""
	Set Query = Query_" SELECT ID, Type, SourceConfigName, TargetConfigName, ErrorStatus"
	Set Query = Query_"   FROM Ens.MessageHeader WHERE IsError = 1"
	Set Query = Query_"    AND SessionID = ?"
	
	#dim rs As %SQL.StatementResult
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, SessionId)
	
	If 'rs.%Next() Quit 0
	
	Set Id = rs.Id
	Set Type = ##class(Ens.DataType.MessageType).LogicalToDisplay(rs.Type)
	Set MessageDesc = Type_" "_rs.SourceConfigName_" ⭢ "_rs.TargetConfigName
	Set Status = rs.ErrorStatus
	
	Quit 1
}

}

