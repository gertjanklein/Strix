Include Strix

/// This class supports easily running repeatable, long-running tasks in a
/// background job. Each task type should be a subclass of this class; each
/// task run will be an instance. This facilitates storing information on
/// the state of a running task, errors that have occurred, etc.
/// 
/// Some of the properties of this class that store task- and job-related
/// info are State, Status, and JobId. These are set by the support code
/// and should not be set by other code.
/// 
/// Properties that store commonly used task-specific information are Ids
/// and Results; if and how these are used is up to the task.
/// 
/// Tasks (subclasses) should create one or two methods:
/// 
/// - A classmethod that creates a new instance (object), places the data
///   required to perform the task in the instance properties, and calls the
///   StartBackgroundJob method on that instance. It should pass the name of
///   the method described next. For simple cases, existing classmethod
///   RunWithIds may be sufficient.
/// 
/// - A method that will be run in a job, that does the actual work, based
///   on the data placed in the instance by the previous method. This method
///   will be called by the StartBackgroundJob code. It should return a
///   %Status, which will be placed in property Status.
/// 
/// Additional (pairs of) methods may be created if multiple related tasks
/// are to be placed in the same class.
Class Strix.Background.Job Extends %Persistent
{

// ===== General state of the task, not to be set directly

/// The status of the job; initially empty
///   RUNNING:   currently running
///   DONE:      handled and no errors detected
///   ERRORS:    handled and errors detected
///   LOCKFAIL:  failed to acquire lock
Property State As %String(VALUELIST = ",RUNNING,DONE,ERRORS,LOCKFAIL");

/// The %Status returned from the jobbed method
Property Status As %Status;

/// The id ($Job) of the job executing the background task
Property JobId As %String;

/// The method that to run on this object; useful for tasks with
/// multiple methods.
Property MethodName As %String;

/// Date/time the actual job was started
Property DateTimeStarted As %TimeStamp;

/// Date/time the job was completed
Property DateTimeCompleted As %TimeStamp;

/// Id of the user that started the job
Property UserId As %String;

/// If locking is implemented and aquiring a lock failed, this property
/// will be updated with the id of the Job instance that held the lock.
Property LockHeldBy As %String;

// ===== Generic task-specific information; may not be needed/used

/// The ids this background job should operate on
Property Ids As list Of %String(MAXLEN = "", STORAGEDEFAULT = "array");

/// The results of this operation; may be only errors, or information as well
Property Results As list Of Strix.Background.ItemInfo(STORAGEDEFAULT = "array");

/// Progress of the job, if possible to calculate. An integer between 0 and
/// 100 (i.e., a percentage). Empty if undetermined.
Property Progress As %Integer;

// =====

/// Generic helper. Creates a new BackgroundJob instance, copies the
/// Ids into it, and calls the method in a background job. Returns the
/// id of the instance that was created.
ClassMethod RunWithIds(MethodName As %String, Ids As %ListOfDataTypes, UserId As %String = "", Output Status As %Status) As %String
{
	Set Me = ..%New()
	
	For i = 1:1:Ids.Count() Do Me.Ids.Insert(Ids.GetAt(i))
	Set Me.UserId = UserId
	
	Set Status = Me.StartBackgroundJob(MethodName)
	If 'Status Set Status = $$$BuildErr("Error starting background job:", Status)
	
	Quit Me.%Id()
}

/// Starts a job in the current instance. Assumes that any job-specific data
/// is already present in the object. If MethodName is not specified, the
/// corresponding property should be set.
Method StartBackgroundJob(MethodName As %String = "") As %Status
{
	If MethodName '= "" Set ..MethodName = MethodName
	
	If ..MethodName = "" Quit $$$BuildErr("Can't start job: MethodName not specified.", 1)
	
	Set Status = ..%Save()
	If 'Status Quit $$$BuildErr("Can't start job: can't save background job object:", Status)
	
	Job $ZObjClassMethod(..%ClassName(1), "RunJob", ..%Id())::20
	If '$Test Quit $$$BuildErr("Error creating background job for batchjob '"_..%Id()_"'.", 1)
	
	Quit $$$OK
}

/// Given a job object id, checks whether it is still running. Also returns whether
/// errors were detected, and the content of the Progress property.
ClassMethod CheckRunning(JobObjectId As %String, Output Running As %Boolean, Output Errors As %Boolean, Output Progress As %Integer) As %Status
{
	Set (Running, Errors, Progress) = ""
	
	Set Me = ..%OpenId(JobObjectId, , .Status)
	If 'Status Quit $$$BuildErr("Error opening object with id '"_JobObjectId_"':", Status)
	
	;If not completed, check if job is still there
	If Me.DateTimeCompleted '= "", Me.JobId, '$Data(^$Job(Me.JobId)) {
		;Job gone; store error
		Set Me.State = "ERRORS"
		Set Me.Status = $$$BuildErr("Job disappeared.", 1)
		Do Me.%Save()
	}
	
	Set Running = Me.DateTimeCompleted '= ""
	Set Errors =  Me.State = "ERRORS"
	Set Progress = Me.Progress
	
	Quit $$$OK
}

/// Clears the results and tries the operation again. Useful in case the entire task
/// failed (e.g. due to connection issues).
Method Retry() As %Status
{
	Set ..State = ""
	Set ..Status = ""
	Set ..JobId = ""
	Set ..LockHeldBy = ""
	Set ..DateTimeCompleted = ""
	Do ..Results.Clear()
	
	Set Status = ..%Save()
	If 'Status Quit $$$BuildErr("Error saving updated object", Status)
	
	Set Status = ..StartBackgroundJob(..MethodName)
	If 'Status Quit Status
	
	Quit $$$OK
}

/// Clears the results and tries the operation again in the current job.
/// Useful in case the entire task failed for unknown reasons.
ClassMethod ForegroundRetry(JobId As %String) As %Status
{
	Set Me = ..%OpenId(JobId, , .Status)
	If 'Status Quit $$$BuildErr("Error opening job '"_JobId_"'", Status)
	
	Set Me.State = ""
	Set Me.Status = ""
	Set Me.JobId = ""
	Set Me.LockHeldBy = ""
	Set Me.DateTimeCompleted = ""
	Do Me.Results.Clear()
	
	Set Status = Me.%Save()
	If 'Status Quit $$$BuildErr("Error saving updated job object", Status)
	
	Kill Me
	
	Do ..RunJob(JobId)
	
	Quit $$$OK
}

/// Shortcut: adds a JobItemInfo object of type error to ..Results
Method AddErrorInfo(Message As %String, Status As %Status, RelatedId As %String) As %Status
{
	Set Info = ##class(Strix.Background.ItemInfo).GetError(Message, Status, RelatedId)
	Do ..Results.Insert(Info)
	Set Status = ..%Save()
	If 'Status Quit $$$BuildErr("Error updating object "_..%Id()_":", Status)
	
	Quit $$$OK
}

/// For all non-completed jobs, check if the process is still running.
ClassMethod CheckJobs() As %Status
{
	Set Query = "SELECT ID FROM WebServices_Utilities_Background.Job WHERE DateTimeCompleted IS NULL AND State = 'RUNNING'"
	
	Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set Status = rs.Prepare(Query)
	If 'Status Quit $$$BuildErr("Error in query prepare:", Status)
	
	Set Status = rs.Execute()
	If 'Status Quit $$$BuildErr("Error in query execute:", Status)
	
	While rs.Next() {
		Set Id = rs.Get("ID")
		;CheckRunning will attempt to update object state if job is gone.
		Do ..CheckRunning(Id)
	}
	
	Quit $$$OK
}

// =====

/// Attempts to aquire a lock for the job. If locking is unsuccessful,
/// returns the id of the job holding the lock in parameter HeldBy.
/// The (this) default implementation always returns success; subclasses
/// can override this method if actual locking is desired.
Method Lock(Output HeldBy As %String) As %Boolean
{
	Set HeldBy = ""
	Quit 1
}

/// This method will be called when the job is done, and can be used
/// to implement cleanup code. The default implementation does nothing.
Method Unlock()
{
	Quit
}

// =====

/// Method runner: runs a method on the specified object instance. Called from
/// StartBackgroundJob. Not (normally) to be called directly.
ClassMethod RunJob(JobObjectId As %String)
{
	Set $ZTrap = "Error"
	
	;Open the requested instance:
	Set Me = ..%OpenId(JobObjectId, , .Status)
	If 'Status Do $$$LogStatusError("Error opening object "_JobObjectId_":", Status) Quit
	
	Set Me.JobId = $Job
	Set Me.DateTimeStarted = $ZDateTime($ZUtil(188), 3, 1, 1)
	Set Status = Me.%Save()
	
	;Attempt lock (if implemented)
	Set HeldBy = -1
	If 'Me.Lock(.HeldBy) {
		Set Me.LockHeldBy = HeldBy
		Set Me.State = "LOCKFAIL"
		Set Me.DateTimeCompleted = $ZDateTime($ZUtil(188), 3, 1, 1)
		Set Status = Me.%Save()
		If 'Status Do $$$LogStatusError("Error saving instance "_Me.%Id()_"; locking failed, HeldBy = '"_HeldBy_"'.", Status)
		Quit
	}
	
	Set Me.State = "RUNNING"
	Set Status = Me.%Save()
	
	;Run the requested method:
	Try {
		Set Status = $ZObjMethod(Me, Me.MethodName)
		
	} Catch e {
		If e.Name = "<COMMAND>" {
			;The method we called didn't return anything.
			Set Status = $$$OK
		} Else {
			;Something else went wrong; get a status describing the problem.
			Set Status = e.AsStatus()
		}
	}
	
	;Update this object
	Set Me.Status = Status
	Set Me.DateTimeCompleted = $ZDateTime($ZUtil(188), 3, 1, 1)
	
	Set ErrorsFound = 0
	For i = 1:1:Me.Results.Count() If Me.Results.GetAt(i).IsError Set ErrorsFound = 1 Quit
	Set Me.State = $Select(Status && 'ErrorsFound: "DONE", 1: "ERRORS")
	
	;Convenience: if progress is used/set by this task, set it to 100 (done).
	If Me.Progress '= "", (Me.State = "DONE") || (Me.Progress = 99) Set Me.Progress = 100
	
	Do Me.Unlock()
	
	Set Status = Me.%Save()
	If 'Status Do $$$LogStatusError("Error saving object "_JobObjectId_":", Status)
	
	Quit
	
Error
	Set $ZTrap = ""
	Do $$$LogTrappedError("MethodName = '"_$Get(MethodName)_"', JobObjectId = '"_$Get(JobObjectId)_"'.")
}

Storage Default
{
<Data name="Ids">
<Attribute>Ids</Attribute>
<Structure>subnode</Structure>
<Subscript>"Ids"</Subscript>
</Data>
<Data name="JobDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>State</Value>
</Value>
<Value name="3">
<Value>Status</Value>
</Value>
<Value name="4">
<Value>JobId</Value>
</Value>
<Value name="5">
<Value>MethodName</Value>
</Value>
<Value name="6">
<Value>DateTimeStarted</Value>
</Value>
<Value name="7">
<Value>DateTimeCompleted</Value>
</Value>
<Value name="8">
<Value>UserId</Value>
</Value>
<Value name="9">
<Value>LockHeldBy</Value>
</Value>
<Value name="10">
<Value>Progress</Value>
</Value>
</Data>
<Data name="Results">
<Attribute>Results</Attribute>
<Structure>subnode</Structure>
<Subscript>"Results"</Subscript>
</Data>
<DataLocation>^Strix.Background.JobD</DataLocation>
<DefaultData>JobDefaultData</DefaultData>
<IdLocation>^Strix.Background.JobD</IdLocation>
<IndexLocation>^Strix.Background.JobI</IndexLocation>
<StreamLocation>^Strix.Background.JobS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
