/// Information for requesting a page from a resultset
Class Strix.Resultset.Request Extends %RegisteredObject
{

/// The id of the resultset containing all results.
Property ResultsetId As %String;

/// The number of items to return for one page of results
Property PageSize As %Integer;

/// The (one-based) number of the page to return
Property PageNumber As %Integer;

// =====

/// The session key (normaly: login id) for this request. Only used server-side.
Property SessionKey As %String(XMLPROJECTION = "NONE");

}
