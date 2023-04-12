/// Tests Strix.Lib.Spooler
Class Strix.Tests.Spooler Extends Strix.Testing.TestCase
{

/// Test that nested spoolers work: closing the "inner" spooler
/// should re-open the "outer" spooler.
Method TestReentrancy()
{
	; Start first spooler and write something
	Set Spooler1 = ##class(Strix.Lib.Spooler).Start()
	Write 1,!,2,!,3,!
	
	; Start second spooler and write something
	Set Spooler2 = ##class(Strix.Lib.Spooler).Start()
	Write "Line for 2!",!
	
	Set Spooler2Out = Spooler2.Stop()
	Write "Line for 1!",!
	
	Set Spooler1Out = Spooler1.Stop()
	
	Do ..AssertEqual(Spooler2Out, "Line for 2!"_$c(13,10), "Inner spooler filed one line")
	Do ..AssertEqual(Spooler1Out, 1_$c(13,10)_2_$c(13,10)_3_$c(13,10)_"Line for 1!"_$c(13,10),
	  "Outer spooler filed pre- and post-inner lines")
	
	Quit
}

}

