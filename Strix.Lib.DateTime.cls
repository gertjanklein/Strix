/// DateTime represented internally as a $Horolog value.
Class Strix.Lib.DateTime Extends %DataType [ OdbcType = TIMESTAMP, SqlCategory = TIMESTAMP ]
{

/// XMLTIMEZONE specifies the handling of timezone part of the XML format dateTime.
/// "UTC" means convert to UTC on input.  "IGNORE means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "IGNORE";

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "dateTime";

// =====

/// Converts the SOAP encoded input dateTime value into a DateTime value.
ClassMethod XSDToLogical(%val As %String) As Strix.Lib.DateTime [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" If $length($get(%val),""T"")'=2 Quit """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"","" "")")
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" {")
		$$$GENERATE("   Set dt=$extract(dt,1,len-1)")
		$$$GENERATE(" } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("   If $extract(%val,len-2)'="":"" Quit """"")
		$$$GENERATE("   Set dt=$extract(dt,1,len-6)")
		If %parameter("XMLTIMEZONE")'="IGNORE" {
			$$$GENERATE("   Set f=$piece(dt,""."",2) If f'="""" Set f="".""_f,dt=$piece(dt,""."")")
			$$$GENERATE("   Set t=$zdatetimeh(dt,3,1,,,,,,,"""") If t="""" Quit """"")
			$$$GENERATE("   Set d=$piece(t,"","")")
			$$$GENERATE("   Set s=$piece(t,"","",2)")
			$$$GENERATE("   Set z=($extract(%val,len-4,len-3)*60+$extract(%val,len-1,len))*60")
			$$$GENERATE("   If $extract(%val,len-5)=""-"" {")
			$$$GENERATE("     Set s=s+z")
			$$$GENERATE("     If s>=(24*60*60) Set d=d+1,s=s-(24*60*60)")
			$$$GENERATE("   } Else {")
			$$$GENERATE("     Set s=s-z")
			$$$GENERATE("     If s<0 Set d=d-1,s=s+(24*60*60)")
			$$$GENERATE("   }")
			$$$GENERATE("   If $zdatetime(d_"",""_s,3,1,0,,,,,,,"""")="""" Quit """"")
			$$$GENERATE("   Quit d_"",""_s")
		}
		$$$GENERATE(" }")
		$$$GENERATE(" Set dt=$zdatetimeh(dt,3,1,,,,,,,"""")")
		$$$GENERATE(" Quit dt")
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the DateTime value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As Strix.Lib.DateTime) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If %parameter("XMLTIMEZONE")="IGNORE" {
			Set %code="$translate($ZDateTime(%val,3,1),"" "",""T"")"
		} Else {
			Set %code="$select(%val="""":"""",1:$translate($ZDateTime(%val,3,1),"" "",""T"")_""Z"")"
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

// =====

/// Converts <var>%val</var>, which represents either a Timestamp in ODBC format,
/// or a Date in ODBC format, into a DateTime value.
ClassMethod OdbcToLogical(%val As %String) As Strix.Lib.DateTime [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" Quit $zdth(%val,3,1,,,,,,,"""")")
	Quit $$$OK
}

/// Converts a DateTime value into ODBC format.
ClassMethod LogicalToOdbc(%val As Strix.Lib.DateTime) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" Quit $s(%val="""":"""",1:$zdt(%val,3,1,,,,,,,,""""))")
	Quit $$$OK
}

// =====

/// Converts <var>%val</var>, which represents a date or date+time in
/// display format, into a DateTime value.
ClassMethod DisplayToLogical(%val As %String) As Strix.Lib.DateTime [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" Quit $zdth(%val,3,1,,,,,,,"""")")
	Quit $$$OK
}

/// Converts a DateTime value into display format.
ClassMethod LogicalToDisplay(%val As Strix.Lib.DateTime) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" Quit $s(%val="""":"""",1:$zdt(%val,3,1,,,,,,,,""""))")
	Quit $$$OK
}

// =====

ClassMethod IsValid(%val As Strix.Lib.DateTime) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	$$$GENERATE(" If $zdt(%val,3,1,,,,,,,,""error"")=""error"" Quit $$$ERROR($$$DTFailure,%val)")
	$$$GENERATE(" Quit $$$OK")
	Quit $$$OK
}

}

