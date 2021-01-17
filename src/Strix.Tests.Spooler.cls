/// Tests Strix.Lib.Spooler
Class Strix.Tests.Spooler Extends Strix.Testing.TestCase
{

/// Test that nested spoolers work: closing the "inner" spooler
/// should re-open the "outer" spooler.
Method TestReentrancy()
{
	; Start first spooler and write something
	Set Spooler1 = ##class(Strix.Lib.Spooler).Start()
	Write "Line 1!",!
	
	; Start second spooler and write something
	Set Spooler2 = ##class(Strix.Lib.Spooler).Start()
	Write "Line 2!",!
	
	Set Spooler2Out = Spooler2.Stop()
	Write "Line 3!",!
	
	Set Spooler1Out = Spooler1.Stop()
	
	Do ..AssertEqual(Spooler2Out, "Line 2!"_$c(13,10), "Inner spooler filed one line")
	Do ..AssertEqual(Spooler1Out, "Line 1!"_$c(13,10)_"Line 3!"_$c(13,10), "Outer spooler filed two lines")
	
	Quit
}

}

