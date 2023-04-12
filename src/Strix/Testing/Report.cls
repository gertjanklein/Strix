/// Displays HTML report for saved test runs.
Class Strix.Testing.Report Extends %CSP.Page
{

/// Dispatcher; delegates to list, report, assertion, or error page
ClassMethod OnPage() As %Status
{
	#dim %request As %CSP.Request
	If '%request.IsDefined("id") Quit ..ListPage()
	
	Set Id = %request.Get("id", 9)
	Set Run = ##class(Strix.Testing.Runner).%OpenId(Id,,.sc)
	If 'sc Quit ..ErrorPage("Error opening run object {}:", sc, Id)
	
	If %request.IsDefined("a") {
		Set AsrtNr = %request.Get("a")
		If (AsrtNr < 1) || (AsrtNr > Run.Results.Count()) {
			Quit ..ErrorPage("Invalid assertion number {} for run {}.",, AsrtNr, Id)
		}
		Quit ..AssertionPage(Run, AsrtNr)
	}
	
	Quit ..TestRunPage(Run)
}

// =====

/// Displays a page listing the saved test runs
ClassMethod ListPage() As %Status
{
	&html<<!DOCTYPE html>
<html lang=en>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<title>Saved test runs</title>
#(..PageCSS())#
#(..ListCSS())#
</head>
<body>
<h1>Saved test runs</h1>
<table id=runlist>
 <thead>
  <tr>
   <th>Run</th>
   <th>When</th>
   <th>Spec</th>
   <th>Problems</th>
   <th>Tests</th>
  </tr>
</thead>
 <tbody>>
	
	#dim rs As %SQL.StatementResult
	Set Query = "SELECT ID FROM Strix_Testing.Runner ORDER BY ID DESC"
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query)
	While rs.%Next() {
		Set Id = rs.ID
		Set Run = ##class(Strix.Testing.Runner).%OpenId(Id, , .sc)
		If 'sc {
			Set Msg = "Error opening test run "_Id_": "_$System.Status.GetErrorText(sc)
			&html<<tr class="syserr"><td colspan=5>#($ZConvert(Msg, "O", "HTML"))#</td></tr>>
			Continue
		}
		
		&html<
  <tr class=#($Select(Run.Errors:"Error",Run.Failed:"Fail",1:"Pass"))#>
   <td><a href="?id=#(Id)#">#(Id)#</a></td>
   <td>#($Piece(Run.UTCTimestampToLocal(Run.TestRunStart), "."))#</td>
   <td>#(Run.TestSpec)#</td>
   <td>#(Run.Failed)# failed assertions, #(Run.Errors)# errors</td>
   <td>#(Run.Asserts)# assertions checked; #(Run.Skipped)# skipped.</td>
  </tr>>
	}
	
	&html<
</tbody>
</table>
</body>
</html>>
	
	Quit $$$OK
}

// =====

/// Displays a page showing the results of a single test run
ClassMethod TestRunPage(Run As Strix.Testing.Runner, Full As %Boolean = 1) As %Status
{
	&html<<!DOCTYPE html>
<html lang=en>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<title>Test run report</title>
#(..PageCSS())#
#(..NavigationCSS())#
#(..SummaryCSS())#
#(..AssertionListCSS())#>
	If Run.Errors+Run.Failed Do ..ErrorAssertionCSS()
	&html<<style type="text/css">
#summ + .asrt { margin-top: 1.5em; }
.asrt + #reslist { margin-top: 1.5em; }
#summ + #reslist { margin-top: 1.5em; }
</style>
<style type="text/css">
</style>
</head>
<body>
<h1>Test run report</h1>
#(..TestRunNavigation(Run.%Id()))#
<h2>Summary:</h2>
#(..TestRunSummary(Run))#>
	If Run.Errors+Run.Failed &html<
<h2>Failed assertions/errors:</h2>
#(..AssertionErrors(Run))#>
	If Full &html<
<h2>Successfull assertions:</h2>
#(..AssertionSummary(Run))#>
	&html<</body>
</html>>
	
	Quit $$$OK
}

/// Writes HTML for the results summary
ClassMethod TestRunSummary(Run As Strix.Testing.Runner) As %String
{
	&html<
<table id="summ">
<tr>
 <th>Run number:</th>
 <td>#(Run.%Id())#</td>
</tr>
<tr>
 <th>Started:</th>
 <td>#(Run.UTCTimestampToLocal(Run.TestRunStart))#</td>
</tr>
<tr>
 <th>Spec:</th>
 <td>#(Run.TestSpec)#</td>
</tr>
<tr #($Select(Run.Errors:"class=Error",Run.Failed:"class=Fail",1:""))#>
 <th>Problems:</th>
 <td>#(Run.Failed)# failed assertions, #(Run.Errors)# errors</td>
</tr>
<tr>
 <th>Tests:</th>
 <td>#(Run.Asserts)# assertions in #(Run.Tests)# test methods in
     #(Run.TestCases)# classes; #(Run.Skipped)# assertions skipped.</td>
</tr>
</table>>
	
	Quit ""
}

/// Writes HTML for the assertion table
ClassMethod AssertionSummary(Run As Strix.Testing.Runner, AddLinks As %Boolean = 1, NoErrors As %Boolean = 1) As %String
{
	&html<
<table id="reslist">
 <thead>
  <tr>
   <th>#</th>
   <th>Result</th>
   <th>Type</th>
   <th>Where</th>
  </tr>
</thead>
<tbody>>
	
	For Nr = 1:1:Run.Results.Count() {
		Set Result = Run.Results.GetAt(Nr)
		If NoErrors, $lf($lfs("Fail,Error"), Result.Type) Continue
		Set Where = Result.ClassName_":"_Result.MethodName
		If Result.BackgroundLocation '= "" Set Where = Where_" ⇨<br>"_Result.BackgroundLocation
		
		&html<  <tr class="#(Result.Type)#">>
		If AddLinks {
			&html<   <td rowspan=2><a href="?id=#(Run.%Id())#&amp;a=#(Nr)#">#(Nr)#</a></td>>
		} Else {
			&html<   <td rowspan=2>#(Nr)#</td>>
		}
		&html<   <td rowspan=2>#(Result.Type)#</td>
     <td>#(Result.AssertionType)#</td>
     <td>#(Where)#</td>
    </tr>
    <tr class="#(Result.Type)#Desc">
     <td colspan=2>#($ZConvert(Result.Description, "O", "HTML"))#</td>
    </tr>>
	}
	
	&html<
</tbody>
</table>>
	
	Quit ""
}

/// Writes HTML for failed assertions and errors
ClassMethod AssertionErrors(Run As Strix.Testing.Runner, AddLinks As %Boolean = 1)
{
	&html<
<table class=asrt>>
	For Nr = 1:1:Run.Results.Count() {
		Set Result = Run.Results.GetAt(Nr)
		If '$lf($lb("Fail","Error"), Result.Type) Continue
		Set Where = Result.ClassName_":"_Result.MethodName
		If Result.BackgroundLocation '= "" Set Where = Where_" ⇨<br>"_Result.BackgroundLocation
		&html<
<tbody class=asrt>
<tr>
<th>Nr:</th>>
	If AddLinks {
		&html<   <td><a href="?id=#(Run.%Id())#&amp;a=#(Nr)#">#(Nr)#</a></td>>
	} Else {
		&html<   <td>#(Nr)#</td>>
	}
	&html<</tr>
<tr>
 <th>Result:</th>
 <td class="#(Result.Type)#">#(Result.Type)#</td>
</tr>
<tr>
 <th>Type:</th>
 <td>#(Result.AssertionType)#</td>
</tr>
<tr>
 <th>Where:</th>
 <td>#(Where)#</td>
</tr>
<tr>
 <th>Description:</th>
 <td class=Desc>#($ZConvert(Result.Description, "O", "HTML"))#</td>
</tr>>
		; For some assertions we don't need to show the expected value
		Set NoExpect = $lfs("Assert,AssertTrue,AssertFalse,AssertStatusOk")
		If '$lf(NoExpect, Result.AssertionType), Result.Type '= "Error" {
			Set Expected = $ZConvert($$Quote^%qcr(Result.Expected), "O", "HTML")
			&html<<tr>
 <th>Expected:</th>
 <td>#(Expected)#</td>
</tr>>
		}
	
		If Result.Type '= "Error" {
			Set Got = $ZConvert($$Quote^%qcr(Result.Result), "O", "HTML")
			&html<<tr>
 <th>Result:</th>
 <td>#(Got)#</td>
</tr>>
		}
		&html<</tbody>>
	}
	
	&html<</table>>
	
	Quit ""
}

/// Writes HTML to navigate to the previous/next/first/last test run.
ClassMethod TestRunNavigation(Id As %String = "") As %String
{
	Set (First, Prev, Next, Last) = ""
	
	If Id '= "" {
		Set Query = "SELECT TOP 1 ID FROM Strix_Testing.Runner WHERE ID < ? ORDER BY ID DESC"
		Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, Id)
		If rs.%Next() Set Prev = rs.ID
		
		Set Query = "SELECT TOP 1 ID FROM Strix_Testing.Runner WHERE ID > ? ORDER BY ID"
		Set rs = ##class(%SQL.Statement).%ExecDirect(, Query, Id)
		If rs.%Next() Set Next = rs.ID
	}
	
	Set Query = "SELECT TOP 1 ID FROM Strix_Testing.Runner ORDER BY ID"
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query)
	If rs.%Next() Set First = rs.ID
	
	Set Query = "SELECT TOP 1 ID FROM Strix_Testing.Runner ORDER BY ID DESC"
	Set rs = ##class(%SQL.Statement).%ExecDirect(, Query)
	If rs.%Next() Set Last = rs.ID
	
	If First_Prev_Next_Last {
		&html<<nav>>
		&html<<a href="?">↑ List</a>>
		
		If First '= "", First '= Id {
			&html<<a href="?id=#(First)#">⇤ First</a>>
		} Else { &html<<span>⇤ First</span>>}
		
		If Prev '= "" {
			&html<<a href="?id=#(Prev)#">← Previous</a>>
		} Else { &html<<span>← Previous</span>>}
		
		If Next '= "" {
			&html<<a href="?id=#(Next)#">→ Next</a>>
		} Else { &html<<span>→ Next</span>>}
		
		If Last '= "", Last '= Id {
			&html<<a href="?id=#(Last)#">⇥ Last</a>>
		} Else { &html<<span>⇥ Last</span>>}
		
		&html<</nav>>
	}
	
	Quit ""
}

// =====

/// Displays a page showing assertion details.
ClassMethod AssertionPage(Run As Strix.Testing.Runner, Index As %Integer) As %Status
{
	#dim Result As Strix.Testing.Result
	Set Result = Run.Results.GetAt(Index)
	
	Set Where = Result.ClassName_":"_Result.MethodName
	If Result.BackgroundLocation '= "" Set Where = Where_" ⇨<br>"_Result.BackgroundLocation
	
	&html<<!DOCTYPE html>
<html lang=en>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<title>Assertion #(Index)# in run #(Run.%Id())#</title>
#(..PageCSS())#
#(..NavigationCSS())#
#(..ErrorAssertionCSS())#
<style type="text/css">
</style>
</head>
<body>
<h1>Assertion #(Index)# in run #(Run.%Id())#</h1>
#(..AssertionNavigation(Run, Index))#
<table class="asrt">
<tr>
 <th>Result:</th>
 <td class="#(Result.Type)#">#(Result.Type)#</td>
</tr>
<tr>
 <th>Type:</th>
 <td>#(Result.AssertionType)#</td>
</tr>
<tr>
 <th>Where:</th>
 <td>#(Where)#</td>
</tr>
<tr>
 <th>Description:</th>
 <td class=Desc>#($ZConvert(Result.Description, "O", "HTML"))#</td>
</tr>>
	
	; For some assertions we don't need to show the expected value
	Set NoExpect = $lfs("Assert,AssertTrue,AssertFalse,AssertStatusOk")
	If '$lf(NoExpect, Result.AssertionType), Result.Type '= "Error" {
		Set Expected = $ZConvert($$Quote^%qcr(Result.Expected), "O", "HTML")
		&html<
<tr>
 <th>Expected:</th>
 <td>#(Expected)#</td>>
	}
	
	If Result.Type '= "Error" {
		Set Got = $ZConvert($$Quote^%qcr(Result.Result), "O", "HTML")
		&html<
<tr>
 <th>Result:</th>
 <td>#(Got)#</td>>
	}
	
	&html<</table>
</body>
</html>>
	
	Quit $$$OK
}

/// Writes HTML to navigate to the previous/next/first/last assertion in a run.
ClassMethod AssertionNavigation(Run As Strix.Testing.Runner, Index As %Integer) As %String
{
	Set Max = Run.Results.Count()
	&html<<nav>>
	&html<<a href="?id=#(Run.%Id())#">↑ Testrun</a>>
	
	If Index > 1 {
		&html<<a href="?id=#(Run.%Id())#&amp;a=#(1)#">⇤ First</a>>
		&html<<a href="?id=#(Run.%Id())#&amp;a=#(Index-1)#">← Previous</a>>
	} Else {
		&html<<span>⇤ First</span>>
		&html<<span>← Previous</span>>
	}
	
	If Index < Max {
		&html<<a href="?id=#(Run.%Id())#&amp;a=#(Index+1)#">→ Next</a>>
		&html<<a href="?id=#(Run.%Id())#&amp;a=#(Max)#">⇥ Last</a>>
	} Else {
		&html<<span>→ Next</span>>
		&html<<span>⇥ Last</span>>
	}
	
	&html<</nav>>
	
	Quit ""
}

// =====

/// Returns an HTML report that can be used in an email. If
/// Full is false, only failed assertions and errors will be
/// shown in detail.
ClassMethod ReportMail(Run As Strix.Testing.Runner, Full As %Boolean = 1) As %Stream.TmpCharacter
{
	; Capture output from &html<> statements
	#dim Spooler As Strix.Lib.Spooler
	Set Spooler = ##class(Strix.Lib.Spooler).Start()
	
	&html<<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
#(..PageCSS())#
#(..SummaryCSS())#>
	If Full &html<#(..AssertionListCSS())#>
	If Run.Errors+Run.Failed Do ..ErrorAssertionCSS()
	&html<<style type="text/css">
#summ + .asrt { margin-top: 1.5em; }
.asrt + #reslist { margin-top: 1.5em; }
#summ + #reslist { margin-top: 1.5em; }
</style>
</head>
<body>
<h1>Test run #("#"_Run.%Id())# report</h1>
<h2>Summary:</h2>>
	&html<#(..TestRunSummary(Run))#>
	If Run.Errors+Run.Failed &html<
<h2>Failed assertions/errors:</h2>
#(..AssertionErrors(Run, 0))#>
	If Full &html<
<h2>Successfull assertions:</h2>
#(..AssertionSummary(Run, 0))#>
	&html<</body>
</html>>
	
	Set Mail = ##class(%Stream.TmpCharacter).%New()
	Do Mail.WriteLine(Spooler.Stop())
	
	Quit Mail
}

// =====

/// Displays a page descibing the problem if an error has occurred.
ClassMethod ErrorPage(Message As %String, Status As %Status, Args... As %String) As %Status
{
	For i = 1:1:$Get(Args) Set Message = $Replace(Message, "{}", $Get(Args(i)),, 1)
	Set Status = $System.Status.GetErrorText(Status)
	
	&html<<!DOCTYPE html>
<html lang=en>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<title>An error occurred</title>
<style>
body {
  background-color: #fcc;
  font: 120% Calibri, Arial, sans-serif;
}
</style>
</head>
<body>
<h1>The following error occurred</h1>
#($ZConvert(Message, "O", "HTML"))#<br>
#($ZConvert(Status, "O", "HTML"))#
</body>>
	
	Quit $$$OK
}

// =====

/// Common CSS for all pages
ClassMethod PageCSS() As %String
{
	&html<<style type="text/css">
body { background: #f9f9f9; }
h1 {
	font: italic bold 180% Times, serif;
	background-color: #09c; color: white;
	border: 5px solid #09c; border-radius: 5px;
	padding: 0.2em 0.2em 0.2em 1em;
	margin: 0 0 0.5em 0;
}
h2 {
  margin: 0.6em 0 0.2em 0;
  font: italic 135% Cambria, serif;
}
a, a:visited { color: blue; }
</style>>	
	
	Quit ""
}

/// CSS for the report list page.
ClassMethod ListCSS() As %String
{
	&html<<style type="text/css">
#runlist {
  border-collapse: collapse;
  border: 5px solid #ccc;
  font: 100% Calibri, Arial, sans-serif;
  background-color: white; color: black;
}
#runlist tr:nth-child(even) { background-color: #f9f9f9; }
#runlist th, #runlist td {
  vertical-align: baseline;
  border: 1px solid #ccc;
  padding: 0.15em 0.5em;
  font-weight: normal;
  text-align: left;
}
#runlist th { background-color: #069; color: white; }
#runlist th:first-child, #runlist td:first-child {
  text-align: right;
}
.syserr td { background-color: red; color: #ff9; }
tr.Pass  td:nth-child(4) { background-color: #afa; }
tr.Fail  td:nth-child(4) { background-color: #f99; }
tr.Error td:nth-child(4) { background-color: #f66; }
</style>>	
	
	Quit ""
}

/// CSS for the test run report summary table.
ClassMethod SummaryCSS() As %String
{
	&html<<style type="text/css">
#summ {
  border-collapse: collapse;
  border: 5px solid #ccc;
  font: 100% Calibri, Arial, sans-serif;
  background-color: white; color: black;
}
#summ th, #summ td {
  vertical-align: baseline;
  border: 1px solid #ccc;
  padding: 0.15em 0.5em;
  font-weight: normal;
  text-align: left;
}
#summ th {
  background-color: #069;
  color: white;
}
#summ .Fail td { background-color: #f99; }
#summ .Error td { background-color: #f66; }
</style>>	
	
	Quit ""
}

/// CSS for the test run report assertion list table.
ClassMethod AssertionListCSS() As %String
{
	&html<<style type="text/css">
#reslist {
  border-collapse: collapse;
  border: 5px solid #ccc;
  font: 100% Calibri, Arial, sans-serif;
  background-color: white; color: black;
}
#reslist th, #reslist td {
  vertical-align: baseline;
  border-left: 1px solid #ccc;
  border-right: 1px solid #ccc;
  padding: 0.15em 0.5em;
  font-weight: normal;
  text-align: left;
}
#reslist th {
  background-color: #069;
  border-bottom: 1px solid #ccc;
  color: white;
}
#reslist tbody tr:nth-child(odd) { background-color: white; color: black; }
#reslist tbody tr:nth-child(even) { background-color: #eee; border-bottom: 1px solid #ccc; }
#reslist tbody tr:nth-child(odd) td:first-child {
  text-align: right; background-color: #eee;
}
#reslist tr:first-child th:first-child {
  background-color: #eee; color: green;
  text-align: right; font-weight: bold;
}
#reslist tr.Pass td:nth-child(2), #reslist tr.PassDesc td { background-color: #afa; }
#reslist tr.Fail td:nth-child(2), #reslist tr.FailDesc td { background-color: #f99; }
#reslist tr.Error td:nth-child(2), #reslist tr.ErrorDesc td { background-color: #f66; }
#reslist tr.Skip td:nth-child(2), #reslist tr.SkipDesc td { background-color: #ccc; }
#reslist tr.Log td:nth-child(2), #reslist tr.LogDesc td { background-color: #ded; }
</style>>	
	
	Quit ""
}

/// CSS for display of a single (fail/error) assertion
ClassMethod ErrorAssertionCSS()
{
	&html<<style type="text/css">
.asrt {
  border-collapse: collapse;
  border: 5px solid #ccc;
  font: 100% Calibri, Arial, sans-serif;
  background-color: white; color: black;
}
.asrt th, .asrt td {
  vertical-align: baseline;
  border: 1px solid #ccc;
  padding: 0.15em 0.5em;
  font-weight: normal;
  text-align: left;
}
.asrt th {
  background-color: #069;
  color: white;
}
.asrt td.Desc { background-color: #f3e7dc; }
.asrt td.Pass  { background-color: #afa; }
.asrt td.Skip  { background-color: #ccc; }
.asrt td.Fail  { background-color: #f99; }
.asrt td.Error { background-color: #f66; }
table.asrt tbody + tbody tr:first-child { border-top: 0.5em solid #ccc; }
</style>>	
	
	Quit ""
}

/// CSS for navigation bars
ClassMethod NavigationCSS() As %String
{
	&html<<style type="text/css">
nav { margin-bottom: 1em; }
nav a, nav a:visited, nav span {
	outline: none;
	text-decoration: none;
	display: inline-block;
	font: 100% Calibri, Arial, sans-serif;
	background-color: #069;
	color: white;
	text-align: center;
	padding: 0 0 2px 0;
	border: 2px solid #ccc;
	border-radius: 4px;
	width: 6em;
}
nav span { color: #999; }
</style>>	
	
	Quit ""
}

}

