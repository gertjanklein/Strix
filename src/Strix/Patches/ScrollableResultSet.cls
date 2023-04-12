/// A patched version of %ScrollableResultSet, to fix some bugs that can't be
/// worked around in other ways.
Class Strix.Patches.ScrollableResultSet Extends %Library.ScrollableResultSet
{

/// PopulateData originates in %ScrollableResultSet, and (if successfull)
/// calls Close() (from %ResultSet) to close the original query. That method
/// sets property IsOpened (also from %ResultSet) to 0. The result is that
/// method OpenObject, which checks for IsOpened, no longer works. The fix
/// is to set IsOpened back to 1 after PopulateData.
Method PopulateData() As %Status [ Private ]
{
	Set Status = ##super()
	If 'Status Quit Status
	Set i%IsOpened = 1
	Quit $$$OK
}

}
