/// IBAN-related code
Class Strix.Std.IBAN Extends %RegisteredObject
{

/// Checks if an IBAN is valid
/// See http://en.wikipedia.org/wiki/International_Bank_Account_Number
ClassMethod IsValid(IBAN As %String) As %Boolean
{
	;Strip whitespace, make sure it's in uppercase
	Set IBAN = $ZConvert($Translate(IBAN, " "), "U")
	
	Set CountryCode = $Extract(IBAN, 1, 2)
	Set Check = $Extract(IBAN, 3, 4)
	
	Set Test = ""
	Set Input = $Extract(IBAN, 5, *)_CountryCode
	For i = 1:1:$Length(Input) {
		Set Char = $Extract(Input, i)
		If Char = +Char {
			Set Test = Test_Char
		} Else {
			Set Nr = $Ascii(Char) - $Ascii("A") + 10
			Set Test = Test_Nr
		}
	}
	Set Test = Test_"00"
	Set Test = ..Modulo97(Test)
	Set Test = 98 - Test
	If Test < 10 Set Test = "0"_Test
	
	Quit Test = Check
}

/// Basic formatting for an IBAN: uppercase, spaces every four characters
ClassMethod Format(IBAN As %String) As %String
{
	;Strip whitespace, make sure it's in uppercase
	Set IBAN = $ZConvert($Translate(IBAN, " "), "U")
	
	;Add a space between every four characters
	Set Result = ""
	For Index = 1:4:$Length(IBAN) {
		If Index > 1 Set Result = Result_" "
		Set Result = Result_$Extract(IBAN, Index, Index + 3)
	}
	
	Quit Result
}

/// Performs modulo-97 operation on a large string of digits; the calculation
/// of the checksum above can yield numbers of up to 30 digits, which Caché
/// doesn't support natively.
/// Monkey see, monkey do:
/// http://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
ClassMethod Modulo97(BigNumber As %String) As %String
{
	Set Rem = $Extract(BigNumber, 1, 2)
	For Index = 3:7:$Length(BigNumber) {
		Set NineDigits = Rem_$Extract(BigNumber, Index, Index + 6)
		Set Rem = NineDigits # 97
		If Rem < 10 Set Rem = "0"_Rem
	}
	Quit Rem
}

}

