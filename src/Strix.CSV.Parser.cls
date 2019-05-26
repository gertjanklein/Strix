Include Strix

/// A class to parse CSV data formatted according to RFC4180.
/// Provides a resultset-like interface.
Class Strix.CSV.Parser Extends %RegisteredObject
{

// ----- Input and configuration

/// The input data as a stream
Property Input As %Stream.Object;

/// The separator to use
Property Separator As %String [ InitialExpression = "," ];

/// The number of initial (header) lines to skip on parsing
Property SkipCount As %Integer [ InitialExpression = 0 ];

/// Whether to take column names from the first row
Property NamesFromFirstRow As %Boolean [ InitialExpression = 0 ];

/// If an adaptor class exists for this CSV, specify the name here
/// so ..GetObject works.
Property AdaptorClassName As %String;

// ----- State

/// The number of the current record. This includes header rows,
/// if any.
Property RecordNr As %Integer;

/// Optional mapping of column name to column index
Property Names As %String [ MultiDimensional ];

/// The data indexed by column number
Property Data As %String [ MultiDimensional ];

/// The data indexed by column name
Property DataByName As %String [ MultiDimensional ];

// =====

/// Returns an instance of this class with some properties setup.
ClassMethod GetParser(Input As %AbstractStream, Separator As %String = ",", SkipCount As %Integer = 0, ColumnNames As %String) As Strix.CSV.Parser
{
	Set Me = ..%New()
	Set Me.Input = Input
	Set Me.Separator = Separator
	Set Me.SkipCount = SkipCount
	If SkipCount = 1, '$Data(ColumnNames) Set Me.NamesFromFirstRow = 1
	If $Get(ColumnNames) '= "" Do Me.SetColumnNames(ColumnNames)
	Quit Me
}

ClassMethod FromFile(FileName As %String, Separator As %String = ",", SkipCount As %Integer = 0, ColumnNames As %String) As Strix.CSV.Parser
{
	Set File = ##class(%FileCharacterStream).%New()
	Set Status = File.LinkToFile(FileName)
	Quit ..GetParser(File, Separator, SkipCount, .ColumnNames)
}

/// Get the next record. Returns 0 if no more records available.
Method Next(Output Status As %Status) As %Boolean
{
	For  {
		Set ok = ..GetRecord(.Status)
		If 'ok Quit
		
		; Got record; load names if needed
		
		Set ..RecordNr = ..RecordNr + 1
		If ..RecordNr = 1, ..NamesFromFirstRow Do ..SetColumnNamesFromData()
		If ..RecordNr '> ..SkipCount Continue
		
		; Load ..DataByName
		
		Kill ..DataByName
		Set Name = ""
		For  {
			Set Name = $Order(..Names(Name), 1, Index)
			If Name = "" Quit
			If '$Data(..Data(Index)) Continue
			Set ..DataByName(Name) = ..Data(Index)
		}
		
		Quit
	}
	If 'ok Quit 0
	
	Quit 1
}

/// Returns the data in the specified column for the current record.
/// Parameter Default specifies what to return if a column is requested
/// that wasn't present in the input.
Method Get(ColumnNr As %Integer, Default As %String = "") As %String [ CodeMode = expression ]
{
$Get(i%Data(ColumnNr), Default)
}

/// Returns the data in the column, specified by name, for the current
/// record. If no column with that name is present, or if no data was
/// supplied for it, returns the default value.
Method GetByName(ColumnName As %String, Default As %String = "") As %String
{
	Set ColumnNr = $Get(..Names(ColumnName))
	If ColumnNr = "" Quit Default
	Quit $Get(..Data(ColumnNr), Default)
}

/// Returns the row as a %List.
Method GetAsList() As %List
{
	Set List = ""
	For i = 1:1:..Data {
		Set List = List_$ListBuild(..Data(i))
	}
	Quit List
}

/// If an adaptor class has been created for this CSV (and ..AdaptorClassName
/// has been set), this method returns an instance of that class for the
/// current record.
Method GetObject(Output Status As %Status) As Strix.CSV.Adaptor
{
	Set Status = $$$OK
	
	#dim Adaptor As Strix.CSV.Adaptor
	Set Adaptor = $ZObjClassMethod(..AdaptorClassName, "%New")
	If Adaptor = "" Quit $$$BuildStatus("Error creating instance of '{}':", $Get(%objlasterror), ..AdaptorClassName)
	
	Set Preferred = Adaptor.%GetParameter("PreferredLoader")
	If Preferred = "header" {
		Merge Data = ..DataByName
		Set Status = Adaptor.LoadByHeader(.Data)
	} Else {
		Merge Data = ..Data
		Set Status = Adaptor.LoadByIndex(.Data)
	}
	
	Quit Adaptor
}

// =====

/// Sets the column names to use for method GetByName. Specify as a
/// string, the separator defaults to ..Separator but can be overridden.
Method SetColumnNames(Names As %String, Separator As %String = "")
{
	If Separator = "" Set Separator = ..Separator
	
	For ColumnNr = 1:1:$Length(Names, Separator) {
		Set Name = $ZStrip($Piece(Names, Separator, ColumnNr), "<>W")
		;Name is not required to be present
		If Name = "" Continue
		Set ..Names(Name) = ColumnNr
	}
	
	Quit
}

/// Sets column names from the data in ..Data.
Method SetColumnNamesFromData()
{
	For ColumnNr = 1:1:..Data {
		Set ColumnName = $ZStrip(..Data(ColumnNr), "<>W")
		If ColumnName = "" Set ColumnName = "__"_ColumnNr
		Set ..Names(ColumnName) = ColumnNr
	}
	Quit
}

// ===== Private helper code

/// Retrieve the next record from the input stream. If no more records
/// are present, returns false. In case of quoted fields, a record may
/// span multiple lines. Returns parsing errors, if any, in output
/// parameter Status.
Method GetRecord(Output Status As %Status) As %Boolean
{
	Set Status = $$$OK
	Kill ..Data Set ..Data = 0
	If ..Input.AtEnd Quit 0
	
	Set Line = ..Input.ReadLine( , .Status)
	If 'Status Quit 0
	If Line = "", ..Input.AtEnd Quit 0
	
	; If no quotes data can't span multiple lines or contain separator
	
	If Line '[ """" {
		If Line = "" Quit 1
		Set ..Data = $Length(Line, ..Separator)
		For i = 1:1:..Data {
			Set ..Data(i) = $Piece(Line, ..Separator, i)
		}
		Quit 1
	}
	
	; Quotes present, more elaborate parsing needed.
	
	Set Index = 1
	For  {
		; Check the first char of the record data
		
		Set Char = $Extract(Line, Index)
		If Char = "" {
			; No more data, we're done
			
			Set ..Data($Increment(..Data)) = ""
			Quit
			
		} ElseIf Char = """" {
			; Quoted field, looking for a closing quote
			
			Set Index = Index + 1
			Set FieldData = ""
			For  {
				Set Test = $Find(Line, """", Index)
				If Test = 0 {
					; No closing quote in the rest of this line; append another
					If ..Input.AtEnd {
						Set Msg = "Parsing error: end of data while looking for closing quote in record {}."
						Set Status = $$$BuildStatus(Msg, , ..RecordNr+1)
						Return 0
					}
					Set NextLine = ..Input.ReadLine( , .Status)
					If 'Status Return 0
					Set Line = Line_..Input.LineTerminator_NextLine
					Continue
				}
				
				; Found quote; check next character
				Set NextChar = $Extract(Line, Test)
				If NextChar = "" {
					; End of line: this is the last field
					Set FieldData = FieldData_$Extract(Line, Index, Test-2)
					Set ..Data($Increment(..Data)) = FieldData
					Return 1
				}
				If NextChar = """" {
					; Quote: escaped quote, save and search on
					Set FieldData = FieldData_$Extract(Line, Index, Test-2)_""""
					Set Index = Test + 1
					Continue
				}
				If NextChar = ..Separator {
					; Separator: this was the end of this field
					Set FieldData = FieldData_$Extract(Line, Index, Test-2)
					Set ..Data($Increment(..Data)) = FieldData
					Set Index = Test + 1
					Quit
				}
				
				;Char after "closing" quote should be nothing, quote, or separator
				Set Msg = "Parsing error: lone quote in quoted field at record {}, character {}."
				Set Status = $$$BuildStatus(Msg, , ..RecordNr+1, Test-1)
				Return 0
			}
			
		} ElseIf Char = ..Separator {
			; At the start of the next field, this one is empty
			
			Set ..Data($Increment(..Data)) = ""
			Set Index = Index + 1
			
		} Else {
			; Normal data, look for next separator (ignoring quotes)
			
			Set Test = $Find(Line, ..Separator, Index+1)
			If Test = 0 {
				; No more fields
				Set ..Data($Increment(..Data)) = $Extract(Line, Index, *)
				Quit
			} Else {
				; Found start of next field
				Set ..Data($Increment(..Data)) = $Extract(Line, Index, Test-2)
				Set Index = Test
			}
			
		}
	}
	
	Quit 1
}

}

