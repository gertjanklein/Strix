Include Strix

Class Strix.Lib.StreamUtil [ Abstract ]
{

/// Decodes the base64-encoded data in a stream. Places the result in
/// OutStream if passed in, or the original stream otherwise.
ClassMethod Base64Decode(InStream As %Stream.Object, Output OutStream As %Stream.Object = "") As %Status
{
	If OutStream = "" {
		; Return decoded data in original stream. First copy the encoded
		; data to a temporary stream, and set up InStream and OutStream
		; appropriately.
		
		Set Temp = ##class(%Stream.TmpCharacter).%New()
		Set Status = Temp.CopyFrom(InStream)
		If 'Status Quit $$$BuildErr("Error copying data to temporary stream:", Status)
		
		Set OutStream = InStream
		Do OutStream.Clear()
		Set InStream = Temp
	}
	
	; Rewind for reading
	Set Status = InStream.Rewind()
	If 'Status Quit $$$BuildErr("Error rewinding input stream:", Status)
	
	; Chunk length must be divisible by 4; each 4 base64-encoded bytes
	; yield 3 decoded bytes.
	Set Len = 32760
	
	For  {
		If InStream.AtEnd Quit
		Set Chunk = InStream.Read(Len, .Status)
		If 'Status Return $$$BuildErr("Error reading chunk from stream:", Status)
		If Chunk = "" Continue
		Set Status = OutStream.Write($System.Encryption.Base64Decode(Chunk))
		If 'Status Return $$$BuildErr("Error writing decoded chunk to stream:", Status)
	}
	
	Quit $$$OK
}

/// Base64-encodes the data in a stream. Places the result in
/// OutStream if passed in, or the original stream otherwise.
ClassMethod Base64Encode(InStream As %Stream.Object, Output OutStream As %Stream.Object = "") As %Status
{
	If OutStream = "" {
		; Return encoded data in original stream. First copy the original
		; data to a temporary stream, and set up InStream and OutStream
		; appropriately.
		
		Set Temp = ##class(%Stream.TmpCharacter).%New()
		Set Status = Temp.CopyFrom(InStream)
		If 'Status Quit $$$BuildErr("Error copying data to temporary stream:", Status)
		
		Set OutStream = InStream
		Do OutStream.Clear()
		Set InStream = Temp
	}
	
	; Rewind for reading
	Set Status = InStream.Rewind()
	If 'Status Quit $$$BuildErr("Error rewinding input stream:", Status)
	
	; Chunk length must be divisible by 3; each 3 bytes of input
	; yield 4 base64-encoded bytes.
	Set Len = 24492
	
	For  {
		If InStream.AtEnd Quit
		Set Chunk = InStream.Read(Len, .Status)
		If 'Status Return $$$BuildErr("Error reading chunk from stream:", Status)
		If Chunk = "" Continue
		Set Status = OutStream.Write($System.Encryption.Base64Encode(Chunk))
		If 'Status Return $$$BuildErr("Error writing encoded chunk to stream:", Status)
	}
	
	Quit $$$OK
}

}

