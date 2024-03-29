ROUTINE Strix [Type=INC]
#include %occErrors
#include %occStatus
#include %occReference
#include %occKeyword


#; Macros to get current class and method at compile time. From EnsUtil.inc.
#define CurrentClass $classname()
#define CurrentMethod ##safeexpression(""""_$get(%methodname)_"""")


#; SQL table name for a class. From EnsUtil.inc. Evaluated at runtime,
#; can't be used for embedded SQL.
#define ClassSQLTable(%c) ($$$comClassKeyGet(%c,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(%c,$$$cCLASSsqltablename))


#; Get class or property parameter. From EnsUtil.inc.
#define GetClassParameter(%cls,%parm) $$$comMemberKeyGet(%cls,$$$cCLASSparameter,%parm,$$$cPARAMdefault)
#define GetPropertyParameter(%cls,%prop,%parm) $$$comMemberArrayGet(%cls,$$$cCLASSproperty,%prop,$$$cPROPparameter,%parm)

#; Whether a class has a non-abstract method with the give name
#define HasConcreteMethod(%class,%method) (+$$$comMemberDefined(%class,$$$cCLASSmethod,%method)&&('+$$$comMemberKeyGet(%class,$$$cCLASSmethod,%method,$$$cMETHabstract)))


#; ===== Status

/// Create a %Status from a message and another %Status. The message is
/// wrapped in a general error and prefixed to the status.
#def1arg BuildStatus(%args) ##class(Strix.Lib.Status).BuildStatus(%args)
#; Deprecated name for BuildStatus
#def1arg BuildErr(%args) ##class(Strix.Lib.Status).BuildStatus(%args)

#; Builds a status from a message and status, places it is %objlasterror,
#; and quits it. This is intended only for use in %OnNew, where the %Status
#; return value appears to be ignored -- or at least, not placed in
#; %objlasterror. (2015)
#define QuitErrOnNew(%msg,%sc) Set %objlasterror = $System.Status.AppendStatus($s(%msg'="":$System.Status.Error($$$GeneralError,%msg),1:1),%sc) Quit %objlasterror


#; ===== Formatting

/// Template replace for string formatting
#def1arg BuildStr(%args) ##class(Strix.Lib.String).TemplateReplace(%args)
#def1arg BuildMsg(%args) ##class(Strix.Lib.String).TemplateReplace(%args)


#; ===== Logging

#define LogTrappedError(%msg) ##class(Strix.Lib.Log).LogTrappedError($$$CurrentClass_":"_$$$CurrentMethod,%msg)
#define LogStatusError(%msg,%sc) ##class(Strix.Lib.Log).LogError($$$CurrentClass_":"_$$$CurrentMethod,%msg,%sc)
#define LogError(%msg) ##class(Strix.Lib.Log).LogError($$$CurrentClass_":"_$$$CurrentMethod,%msg)
#define LogInfo(%msg) ##class(Strix.Lib.Log).LogInfo($$$CurrentClass_":"_$$$CurrentMethod,%msg)
#define LogDebug(%msg) ##class(Strix.Lib.Log).LogDebug($$$CurrentClass_":"_$$$CurrentMethod,%msg)


#; Write to terminal if there is one
#define IsTerm (($Principal["|TRM|")||($Principal["|TNT|")||($Principal["/dev/pts/"))
#def1arg ToTerm(%args) If $$$IsTerm { Write %args }


#; ===== Assertions

#define LogAssert(%msg) ##class(Strix.Lib.Log).LogAssert($$$CurrentClass_":"_$$$CurrentMethod,%msg)
#define Assert(%cond) If '(%cond) { Throw ##class(%Exception.General).%New("Assertion error",,,##quote(%cond)) }
#define AssertAndLog(%cond) If '(%cond) { Do $$$LogAssert(##quote(%cond)) Throw ##class(%Exception.General).%New("Assertion error",,,##quote(%cond)) }


#; ===== String helpers

#define StartsWith(%x,%s) ($e(%x,1,$l(%s))=%s)
#define EndsWith(%x,%s) ($e(%x,$l(%x)-$l(%s)+1,*)=%s)

#define Quote(%s) (""""_$Replace(%s,"""","""""")_"""")


#; ===== Fixes

#; Returned by class Config.Databases but only known (in %occErrors) as CPFNameDoesNotExist
#define DatabaseDefinitionDoesNotExist 420


#; =====

#; Directory separator. Returns "\" on Windows, "/" otherwise.
#; ##expression chokes on backslash and can't use ##quote.
#define DirSep ##expression($Select($$$isWINDOWS:""""_$c(92)_"""",1:"""/"""))


