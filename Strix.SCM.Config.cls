/// Basic source control management configuration.
Class Strix.SCM.Config Extends Strix.Lib.Singleton
{

/// The base path of the working copy. All project paths are specified
/// relative to this one.
Property BasePath As %String(TRUNCATE = "");

Storage Default
{
<Data name="ConfigDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BasePath</Value>
</Value>
</Data>
<DataLocation>^Strix.SCM.ConfigD</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<IdLocation>^Strix.SCM.ConfigD</IdLocation>
<IndexLocation>^Strix.SCM.ConfigI</IndexLocation>
<StreamLocation>^Strix.SCM.ConfigS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

