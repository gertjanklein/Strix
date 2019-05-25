<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.Std.IBAN">
<Description>
IBAN-related code</Description>
<Super>%RegisteredObject</Super>
<TimeCreated>63326,54869.397613</TimeCreated>

<Method name="IsValid">
<Description>
Checks if an IBAN is valid
See http://en.wikipedia.org/wiki/International_Bank_Account_Number</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>IBAN:%String</FormalSpec>
<ReturnType>%Boolean</ReturnType>
<Implementation><![CDATA[
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
]]></Implementation>
</Method>

<Method name="Format">
<Description>
Basic formatting for an IBAN: uppercase, spaces every four characters</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>IBAN:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	;Strip whitespace, make sure it's in uppercase
	Set IBAN = $ZConvert($Translate(IBAN, " "), "U")
	
	;Add a space between every four characters
	Set Result = ""
	For Index = 1:4:$Length(IBAN) {
		If Index > 1 Set Result = Result_" "
		Set Result = Result_$Extract(IBAN, Index, Index + 3)
	}
	
	Quit Result
]]></Implementation>
</Method>

<Method name="Modulo97">
<Description>
Performs modulo-97 operation on a large string of digits; the calculation
of the checksum above can yield numbers of up to 30 digits, which Caché
doesn't support natively.
Monkey see, monkey do:
http://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>BigNumber:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Rem = $Extract(BigNumber, 1, 2)
	For Index = 3:7:$Length(BigNumber) {
		Set NineDigits = Rem_$Extract(BigNumber, Index, Index + 6)
		Set Rem = NineDigits # 97
		If Rem < 10 Set Rem = "0"_Rem
	}
	Quit Rem
]]></Implementation>
</Method>
</Class>
</Export>
