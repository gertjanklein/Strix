/// European Article Number (13) validation. This is also called
/// International Article Number; see:
/// https://en.wikipedia.org/wiki/International_Article_Number_%28EAN%29
Class Strix.Std.EAN Extends %RegisteredObject
{

/// Returns a boolean indicating whether the EAN-13 is valid. Supports
/// grouping with spaces, dots, and dashes; output parameter Normalized
/// returns the EAN with those removed.
/// The checksum algorithm is the same as that of ISBN-13, and described here:
/// https://en.wikipedia.org/wiki/International_Standard_Book_Number#ISBN-13_check_digit_calculation
ClassMethod IsValid13(EAN13 As %String, Output Normalized As %String) As %Boolean
{
	Set Normalized = $Translate(EAN13, " -.", "")
	
	If Normalized '? 13N Quit 0
	
	; Add digits; odd ones as-is, even ones times 3
	; Note that many descriptions found on the internet use the terms odd and even
	; seen as starting from the right, reversing their meaning.
	Set Sum = 0
	For i = 1:1:12 {
		Set Digit = $Extract(Normalized, i)
		Set Sum = Sum + $Select(i # 2: Digit, 1: Digit * 3)
	}
	
	; Check digit, added to Sum, makes it an exact multiple of 10
	Set Check = Sum # 10
	If Check Set Check = 10 - Check
	If $Extract(Normalized, 13) '= Check Quit 0
	
	Quit 1
}

/// Returns a boolean indicating whether the EAN-8 is valid. Supports
/// grouping with spaces, dots, and dashes; output parameter Normalized
/// returns the EAN with those removed.
/// The checksum algorithm is similar to that of EAN-13.
ClassMethod IsValid8(EAN8 As %String, Output Normalized As %String) As %Boolean
{
	Set Normalized = $Translate(EAN8, " -.", "")
	
	If Normalized '? 8N Quit 0
	
	; Add digits; odd ones times 3, even ones as-is
	; Note that many descriptions found on the internet use the terms odd and even
	; seen as starting from the right, reversing their meaning.
	Set Sum = 0
	For i = 1:1:7 {
		Set Digit = $Extract(Normalized, i)
		Set Sum = Sum + $Select(i # 2: Digit * 3, 1: Digit)
	}
	
	; Check digit, added to Sum, makes it an exact multiple of 10
	Set Check = Sum # 10
	If Check Set Check = 10 - Check
	If $Extract(Normalized, 8) '= Check Quit 0
	
	
	Quit 1
}

}
