/// Enables/disables a (locale) language. Caché displays messages translated
/// in the language of the server it runs on. It does not offer an option to
/// permanently disable this. By removing the translation strings for the
/// language involved, Caché falls back to English. The removed translation
/// strings are backed up and can be restored later.
Class Strix.Patches.Language Extends %RegisteredObject
{

/// Disables the translation for a given language identifier (e.g. "nl" or "zh-cn").
/// The translations are backed up before removing.
/// 
/// Do ##class(Strix.Patches.Language).Disable("nl")
ClassMethod Disable(Language As %String)
{
	Set Node = $Select($ZV["IRIS": "^%qMsg", 1:"^%qCacheMsg")
	Set BackupNode = Node_"Org"
	
	;Check that the language to disable is present:
	If '$Data(@Node@("%Compiler", Language)) {
		If $Data(@BackupNode@("%Compiler", Language)) {
			Write "Language already disabled.",!
		} Else {
			Write "Language not found.",!
		}
		Quit
	}
	
	;Make sure %SYS is writable:
	Set PrevReadOnly = ##class(Strix.Lib.System).CacheLibReadOnly(0, .Status)
	If 'Status Do $System.Status.DisplayError(Status) Quit
	
	Set Section = ""
	For  {
		Set Section = $Order(@Node@(Section))
		If Section = "" Quit
		If '$Data(@Node@(Section, Language)) Continue
		
		Write "Disabling section "_Section,!
		Merge @BackupNode@(Section, Language) = @Node@(Section, Language)
		Kill @Node@(Section, Language)
	}
	
	If PrevReadOnly {
		Do ##class(Strix.Lib.System).CacheLibReadOnly(1, .Status)
		If 'Status Do $System.Status.DisplayError(Status) Quit
	}
	
	Quit
}

/// Re-enables the translation for a given language identifier.
/// 
/// Do ##class(Strix.Patches.Language).Enable("nl")
ClassMethod Enable(Language As %String)
{
	Set Node = $Select($ZV["IRIS": "^%qMsg", 1:"^%qCacheMsg")
	Set BackupNode = Node_"Org"
	
	;Check that the language to enable is present:
	If '$Data(@BackupNode@("%Compiler", Language)) {
		If $Data(@Node@("%Compiler", Language)) {
			Write "Language already enabled.",!
		} Else {
			Write "Language not found.",!
		}
		Quit
	}
	
	;Make sure %SYS is writable:
	Set PrevReadOnly = ##class(Strix.Lib.System).CacheLibReadOnly(0, .Status)
	If 'Status Do $System.Status.DisplayError(Status) Quit
	
	Set Section = ""
	For  {
		Set Section = $Order(@BackupNode@(Section))
		If Section = "" Quit
		If '$Data(@BackupNode@(Section, Language)) Continue
		
		Write "Re-enabling section "_Section,!
		Merge @Node@(Section, Language) = @BackupNode@(Section, Language)
		Kill @BackupNode@(Section, Language)
	}
	
	If PrevReadOnly {
		Do ##class(Strix.Lib.System).CacheLibReadOnly(1, .Status)
		If 'Status Do $System.Status.DisplayError(Status) Quit
	}
	
	Quit
}

/// Disable translation for Ensemble messages
/// 
/// Do ##class(Strix.Patches.Language).DisableEnsemble("nl")
ClassMethod DisableEnsemble(Language As %String)
{
	;If this is not an Ensemble installation, there's nothing to do here
	If $System.Version.GetISCProduct() '= 2 {
		Write "This is not an Ensemble installation, nothing to do.",!
		Quit
	}
	
	;Get directory, EnsLib database has no namespace
	Set Directory = ##class(Strix.Lib.System).GetDatabaseDirectory("EnsLib", .Status)
	If 'Status {
		Write "An error occurred determining the EnsLib database directory:",!
		Do $System.Status.DisplayError(Status)
		Quit
	}
	Set ExtRef = "^^"_Directory
	
	;Check if data already moved away
	If '$Data(^[ExtRef]CacheMsg("Confirm", Language)) {
		If $Data(^[ExtRef]CacheMsgOrg("Confirm", Language)) {
			Write "Language already disabled.",!
		} Else {
			Write "Language not found.",!
		}
		Quit
	}
	
	Set Section = ""
	For  {
		Set Section = $Order(^[ExtRef]CacheMsg(Section))
		If Section = "" quit
		If '$Data(^[ExtRef]CacheMsg(Section, Language)) Continue
		
		Write "Disabling section "_Section,!
		Merge ^[ExtRef]CacheMsgOrg(Section, Language) = ^[ExtRef]CacheMsg(Section, Language)
		Kill ^[ExtRef]CacheMsg(Section, Language)
	}
	
	Quit
}

/// Re-enables the translation for a given language identifier.
/// 
/// Do ##class(Strix.Patches.Language).EnableEnsemble("nl")
ClassMethod EnableEnsemble(Language As %String)
{
	;If this is not an Ensemble installation, there's nothing to do here
	If $System.Version.GetISCProduct() '= 2 {
		Write "This is not an Ensemble installation, nothing to do.",!
		Quit
	}
	
	;Get directory, EnsLib database has no namespace
	Set Directory = ##class(Strix.Lib.System).GetDatabaseDirectory("EnsLib", .Status)
	If 'Status {
		Write "An error occurred determining the EnsLib database directory:",!
		Do $System.Status.DisplayError(Status)
		Quit
	}
	Set ExtRef = "^^"_Directory
	
	;Check that the language to enable is present:
	
	If '$Data(^[ExtRef]CacheMsgOrg("Confirm", Language)) {
		If $Data(^[ExtRef]CacheMsg("Confirm", Language)) {
			Write "Language already enabled.",!
		} Else {
			Write "Language not found.",!
		}
		Quit
	}
	
	Set Section = ""
	For  {
		Set Section = $Order(^[ExtRef]CacheMsgOrg(Section))
		If Section = "" Quit
		If '$Data(^[ExtRef]CacheMsgOrg(Section, Language)) Continue
		
		Write "Re-enabling section "_Section,!
		Merge ^[ExtRef]CacheMsg(Section, Language) = ^[ExtRef]CacheMsgOrg(Section, Language)
		Kill ^[ExtRef]CacheMsgOrg(Section, Language)
	}
	
	Quit
}

/// Displays all languages for which Caché has translations in CACHELIB.
/// 
/// Do ##class(Strix.Patches.Language).ShowLanguages()
ClassMethod ShowLanguages()
{
	Set Node = $Select($ZV["IRIS": "^%qMsg", 1:"^%qCacheMsg")
	Set BackupNode = Node_"Org"
	
	Set Section = ""
	For  {
		Set Section = $Order(@Node@(Section))
		If Section = "" Quit
		
		Set Language = ""
		For  {
			Set Language = $Order(@Node@(Section, Language))
			If Language = "" Quit
			
			Set Languages(Language) = ""
		}
	}
	
	Write "Available languages:",!
	Set Language = ""
	For  {
		Set Language = $Order(Languages(Language))
		If Language = "" Quit
		
		Write Language,!
	}
	
	;=====
	
	Kill Languages
	Set Section = ""
	For  {
		Set Section = $Order(@BackupNode@(Section))
		If Section = "" Quit
		
		Set Language = ""
		For  {
			Set Language = $Order(@BackupNode@(Section, Language))
			If Language = "" Quit
			
			Set Languages(Language) = ""
		}
	}
	
	If $Order(Languages("")) '= "" {
		Write !,"Disabled languages:",!
		Set Language = ""
		For  {
			Set Language = $Order(Languages(Language))
			If Language = "" Quit
			
			Write Language,!
		}
	}
	
	Quit
}

}

