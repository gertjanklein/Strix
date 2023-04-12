/// VAT number validation
Class Strix.Std.VATNumber Extends %RegisteredObject
{

/// Checks for VAT number validity. Returns 0 (not valid), 1 (valid), or
/// an empty string if unknown. The normalized parameter receives the
/// possibly corrected VAT number; this should be used for external systems.
ClassMethod Check(VATNumber As %String, Output Normalized As %String) As %Boolean
{
	Set CountryCode = $ZConvert($Extract(VATNumber, 1, 2), "U")
	
	;If no country code, check if this is a partial Dutch VAT number.
	If CountryCode '? 2A Quit ..CheckNL(VATNumber, .Normalized)
	
	;Country-specific checks:
	If CountryCode = "NL" Quit ..CheckNL(VATNumber, .Normalized)
	If CountryCode = "BE" Quit ..CheckBE(VATNumber, .Normalized)
	If CountryCode = "DE" Quit ..CheckDE(VATNumber, .Normalized)
	
	;Other countries TBD...
	
	;Return "unknown":
	Quit ""
}

/// Checks a Dutch VAT number
/// Examples: NL820321588B01, NL851332444B01, NL052690210B02
ClassMethod CheckNL(VATNumber As %String, Output Normalized As %String) As %Boolean
{
	Set Normalized = $Translate($ZConvert(VATNumber, "U"), " .")
	
	;Check normal form first
	If Normalized ? 1"NL"9N1"B"2N {
		;Company index should be at least one
		If +$Piece(Normalized, "B", 2) = 0 Quit 0
		
		Set BSN = $Extract($Piece(Normalized, "B"), 3, *)
		Quit ..CheckBSN(BSN)
	}
	
	;Check if NL is left off:
	If Normalized ? 9N1"B"2N, $Piece(Normalized, "B", 2) '= "00", ..CheckBSN($Piece(Normalized, "B")) {
		Set Normalized = "NL"_Normalized
		Quit 1
	}
	
	;Check if Bnn is left off:
	If Normalized ? 1"NL"9N, ..CheckBSN($Extract(Normalized, 3, *)) {
		Set Normalized = Normalized_"B01"
		Quit 1
	}
	
	;Check if both NL and Bnn are left off:
	If Normalized ? 9N, ..CheckBSN(Normalized) {
		Set Normalized = "NL"_Normalized_"B01"
		Quit 1
	}
	
	Quit 0
}

/// Checks a Belgian VAT number
/// Examples: BE0863.982.562, BE0887.052.231, BE0560.869.935
ClassMethod CheckBE(VATNumber As %String, Output Normalized As %String) As %Boolean
{
	Set Normalized = $Translate($ZConvert(VATNumber, "U"), " .")
	
	If Normalized '? 1"BE"1(1"0",1"1")9N Quit 0
	
	Set Check = 97 - ($Extract(Normalized, 4, 10) # 97)
	
	Quit Check = $Extract(Normalized, 11, 12)
}

/// Checks a German VAT number
/// Examples: DE142293940, DE117407655, DE263429934
ClassMethod CheckDE(VATNumber As %String, Output Normalized As %String) As %Boolean
{
	Set Normalized = $Translate($ZConvert(VATNumber, "U"), " .")
	
	If Normalized '? 1"DE"9N Quit 0
	
	Set P = 10
	For i = 1:1:8 {
		Set Char = $Extract(Normalized, i + 2)
		Set M = Char + P # 10
		If 'M Set M = 10
		Set P = 2 * M # 11
	}
	Set P = 11 - P
	If P = 10 Set P = 0
	
	Quit $Extract(Normalized, *) = P
}

/// Checks a Dutch BSN for validity.
/// http://nl.wikipedia.org/wiki/Burgerservicenummer#11-proef
ClassMethod CheckBSN(BSN As %String) As %Boolean
{
	If $Length(BSN) '= 9 Quit 0
	
	Set Sum = 0
	For i = 1:1:9 {
		Set Char = $Extract(BSN, i)
		
		Set Nr = (10 - i) * Char
		If i = 9 Set Nr = -Nr
		Set Sum = Sum + Nr
	}
	
	Quit Sum # 11 = 0
}

}
