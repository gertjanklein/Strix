Include Strix

/// Tests EAN validators
Class Strix.Tests.EAN Extends Strix.Testing.TestCase
{

Method Test13()
{
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid13("0075678164125"), "Valid EAN-13 should return true.")
	Do ..AssertFalse(##class(Strix.Std.EAN).IsValid13("0075678164124"), "Invalid EAN-13 should return false.")
	
	; ISBN is an EAN-13 as well, but formatted with dashes
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid13("978-0-306-40615-7"), "Dash separators should be allowed.")
	
	Quit
}

Method Test8()
{
	Do ..AssertTrue(##class(Strix.Std.EAN).IsValid8("55123457"), "Valid EAN-8 should return true.")
	Do ..AssertFalse(##class(Strix.Std.EAN).IsValid8("55123456"), "Invalid EAN-8 should return false.")
	
	Quit
}

}

