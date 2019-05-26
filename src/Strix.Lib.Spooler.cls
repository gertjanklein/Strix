/// Class interface to the Caché spooler device.
Class Strix.Lib.Spooler Extends %RegisteredObject
{

/// The value of $IO when the spooler is started
Property SavedIO As %String;

/// The spool document number
Property DocumentNumber As %Integer;

/// Data collected by the spool device after method Start is called
/// will be placed here when method Stop is called.
Property Data As %String;

/// Starts the spooler; replaces the current device
ClassMethod Start() As Strix.Lib.Spooler
{
	Set Spooler = ..%New()
	Set Spooler.SavedIO = $IO
	Set Spooler.Data = ""
	Set Spooler.DocumentNumber = Spooler.GetDocNumber()
	Open 2:(Spooler.DocumentNumber)
	Use 2
	Quit Spooler
}

/// Stops the spooler, restores the previous device, and returns any
/// data collected when the spooler was active
Method Stop() As %String
{
	;Stop spooler and restore previous device
	Close 2
	Use ..SavedIO
	
	;Get collected data
	Set Data = ""
	Set LineNr = ""
	For  {
		Set LineNr = $Order(^SPOOL(..DocumentNumber, LineNr), 1, Line)
		If LineNr = "" Quit
		If LineNr = 2147483647 Quit
		Set Data = Data_Line
	}
	Set ..Data = Data
	
	;Clean up
	Kill ^SPOOL(..DocumentNumber)
	Set ..DocumentNumber = ""
	
	;Return data if we're expected to return something
	If $Quit Quit Data
	
	Quit
}

Method GetDocNumber() As %Integer [ Private ]
{
	Lock +^SPOOL
	Set DocumentNumber = $Order(^SPOOL(""), -1) + 1
	Lock -^SPOOL
	Quit DocumentNumber
}

}

