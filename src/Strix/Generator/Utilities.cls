Include Strix

/// Utility code for generator methods in other classes.
Class Strix.Generator.Utilities Extends %RegisteredObject
{

/// Helper: opens a class definition or returns a new one with the specified name.
ClassMethod GetClassDef(Name As %String, Output IsNew As %Boolean, Output Status As %Status) As %Dictionary.ClassDefinition
{
	If ##class(%Dictionary.ClassDefinition).%ExistsId(Name) {
		Set ClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(Name, , .Status)
		Set IsNew = 0
	} Else {
		; Set classversion to 25 to prevent prodedureblock and inheritance
		; getting old default values (off and right, respectively).
		Set ClassDef = ##class(%Dictionary.ClassDefinition).%New(Name, 25)
		Set IsNew = 1, Status = $$$OK
	}
	Quit ClassDef
}

/// Returns a copy of a collection, expected to consist of class definition
/// members, ordered by their SequenceNumber property. This is the order in
/// which they are shown in Studio.
ClassMethod GetOrderedList(Collection As %RelationshipObject, Output Status As %Status) As %Collection.AbstractList
{
	Set Result = ##class(Strix.Lib.Collections).GetCopy(Collection, 1, .Status)
	If 'Status Quit Result
	Set Status = ##class(Strix.Lib.Sorting).SortListOfObjects(Result, "SequenceNumber:::N")
	Quit Result
}

/// Returns an item, specified by name, from a relationship collection
/// (such as CompiledClass:Properties, etc.).
ClassMethod GetInCollection(Collection As %RelationshipObject, Name As %String, Create As %Boolean = 0, Output Status As %Status) As %RegisteredObject
{
	Set Status = $$$OK
	
	Set Found = 0
	Set Key = ""
	For  {
		Set Object = Collection.GetNext(.Key)
		If Key = "" Quit
		If Object.Name = Name Set Found = 1 Quit
	}
	If Found Quit Object
	
	If 'Create Quit ""
	
	Set Object = $ZObjClassMethod(Collection.ElementType, "%New")
	Set Object.Name = Name
	Set Status = Collection.Insert(Object)
	
	Quit Object
}

/// Returns a ParameterDefinition (or CompiledParameter) object with the
/// specified name, if present. ClassNameOrObj can be either a class name
/// or a class definition object.
ClassMethod GetParameter(ClassNameOrObj As %Dictionary.ClassDefinition, ParameterName As %String, Output ParameterDefinition As %Dictionary.ParameterDefinition) As %Status
{
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassNameOrObj = ##class(%Dictionary.CompiledClass).%OpenId(ClassNameOrObj, , .sc)
		If 'sc Quit sc
	}
	
	Set Key = ""
	For  {
		Set ParameterDefinition = ClassNameOrObj.Parameters.GetNext(.Key)
		If Key = "" Quit
		If ParameterDefinition.Name = ParameterName Quit
	}
	
	Quit $$$OK
}

/// Shortcut method to quickly retrieve a parameter value. Returns an empty string
/// in case the parameter doesn't exist or an error occurs.
ClassMethod GetParameterValue(ClassNameOrObj As %Dictionary.ClassDefinition, ParameterName As %String) As %String
{
	Set sc = ..GetParameter(ClassNameOrObj, ParameterName, .ParameterDefinition)
	If 'sc Quit ""
	If '$IsObject(ParameterDefinition) Quit ""
	Quit ParameterDefinition.Default
}

/// Returns a PropertyDefinition (or CompiledProperty) object with the
/// specified name, if present. ClassNameOrObj can be either a class name
/// or a class definition object.
ClassMethod GetProperty(ClassNameOrObj As %Dictionary.ClassDefinition, PropertyName As %String, Output PropertyDefinition As %Dictionary.PropertyDefinition) As %Status
{
	Set PropertyDefinition = ""
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassNameOrObj = ##class(%Dictionary.ClassDefinition).%OpenId(ClassNameOrObj, , .sc)
		If 'sc Quit sc
	}
	
	Set Key = "", Found = 0
	For  {
		Set PropertyDefinition = ClassNameOrObj.Properties.GetNext(.Key)
		If Key = "" Quit
		If PropertyDefinition.Name = PropertyName Set Found = 1 Quit
	
	}
	If 'Found Quit $$$ERROR($$$GeneralError, "Property "_PropertyName_" not found.")
	
	Quit $$$OK
}

/// Returns the global the indices for this class reside in.
ClassMethod GetIndexDefinition(ClassNameOrObj As %Dictionary.ClassDefinition, IndexName As %String, Output IndexDefinition As %Dictionary.IndexDefinition) As %Status
{
	Set IndexDefinition = ""
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassNameOrObj = ##class(%Dictionary.ClassDefinition).%OpenId(ClassNameOrObj, , .sc)
		If 'sc Quit sc
	}
	
	Set Key = "", Found = 0
	For  {
		Set IndexDefinition = ClassNameOrObj.Indices.GetNext(.Key)
		If Key = "" Quit
		
		If IndexDefinition.Name = IndexName Set Found = 1 Quit
	}
	If 'Found Quit $$$ERROR($$$GeneralError, "Property "_IndexName_" not found.")
	
	Quit $$$OK
}

/// Returns the global the indices for this class reside in.
ClassMethod GetIndexLocation(ClassNameOrObj As %Dictionary.ClassDefinition, Output IndexLocation As %String) As %Status
{
	Set IndexLocation = ""
	
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassNameOrObj = ##class(%Dictionary.ClassDefinition).%OpenId(ClassNameOrObj, , .sc)
		If 'sc Quit sc
	}
	
	Set Key = ""
	For  {
		Set StorageDef = ClassNameOrObj.Storages.GetNext(.Key)
		If Key = "" Quit
		
		Set IndexLocation = StorageDef.IndexLocation
		Quit
	}
	
	Quit $$$OK
}

/// Returns a MethodDefinition (or CompiledMethod) object with the
/// specified name, if present. ClassNameOrObj can be either a class name
/// or a class definition object.
ClassMethod GetMethod(ClassNameOrObj As %Dictionary.ClassDefinition, MethodName As %String, Output MethodDefinition As %Dictionary.MethodDefinition) As %Status
{
	Set MethodDefinition = ""
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassNameOrObj = ##class(%Dictionary.ClassDefinition).%OpenId(ClassNameOrObj, , .sc)
		If 'sc Quit sc
	}
	
	Set Key = "", Found = 0
	For  {
		Set MethodDefinition = ClassNameOrObj.Methods.GetNext(.Key)
		If Key = "" Quit
		If MethodDefinition.Name = MethodName Set Found = 1 Quit
	
	}
	If 'Found Quit $$$ERROR($$$GeneralError, "Method "_MethodName_" not found.")
	
	Quit $$$OK
}

/// Returns whether the given method is present and non-abstract.
ClassMethod HasConcreteMethod(ClassDef As %Dictionary.CompiledClass, MethodName As %String) As %Boolean
{
	If '$IsObject(ClassDef) {
		If '##class(%Dictionary.CompiledClass).%ExistsId(ClassDef) Quit 0
		Set ClassDef = ##class(%Dictionary.CompiledClass).%OpenId(ClassDef)
		If '$IsObject(ClassDef) Quit 0
	}
	Set Method = ..GetInCollection(ClassDef.Methods, MethodName)
	If Method = "" Quit 0
	Quit 'Method.Abstract
}

/// Attempts to determine if the given property is a datatype. Non-datatype
/// properties have a few extra system-generated methods such as
/// [Property]SetObjectId. ClassNameOrObj can be either a class name or a
/// class definition object.
/// 
ClassMethod IsDatatype(ClassNameOrObj As %Dictionary.ClassDefinition, PropertyName As %String) As %Boolean
{
	#dim PropDef As %Dictionary.PropertyDefinition
	Set sc = ..GetProperty(ClassNameOrObj, PropertyName, .PropDef)
	If 'sc Quit 1
	
	Set Type = PropDef.Type
	If Type = "" Quit 1
	
	Quit ..ClassIsDataType(Type)
}

/// Returns a flag indicating whether a class can be determined to be a datatype.
ClassMethod ClassIsDataType(ClassName As %String) As %Boolean
{
	Set ClassName = $$$NormalizeClassname(ClassName)
	&sql(SELECT Super INTO :Super FROM %Dictionary.ClassDefinition WHERE Name = :ClassName)
	If SQLCODE Quit ""
	If Super = "" Quit 0
	
	If (Super [ "%DataType") || (Super [ "%Library.DataType") Quit 1
	
	For i = 1:1:$Length(Super, ",") {
		Set ClassName = $Piece(Super, ",", i)
		Set IsDataType = ..ClassIsDataType(ClassName)
		If IsDataType Quit
	}
	
	Quit IsDataType
}

/// Member resolution order / inheritance order.
/// Returns a list of all superclasses of the given class. The order in
/// which they are returned is intended to be the order the compiler
/// uses to determine the origin of a member (if it has multiple origins).
/// Duplicates in the result (if e.g. a class inherits from %XML.Adaptor
/// via multiple superclasses) are removed.
/// 
/// By default, system classes are not returned in the results, but they
/// can be included by clearing ExcludeSystem. If errors occur they are
/// returned in output parameter Status.
/// 
/// See:
/// http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_classes#GOBJ_model_inheritance_mult
/// 
ClassMethod MRO(ClassNameOrObj As %Dictionary.ClassDefinition, ExcludeSystem As %Boolean = 1, Output Status As %Status) As %List
{
	Set Result = ""
	
	If '$IsObject(ClassNameOrObj) {
		;Not an object, so a class name
		Set ClassName = $$$NormalizeClassname(ClassNameOrObj)
		Set ClassNameOrObj = ##class(%Dictionary.ClassDefinition).%OpenId(ClassName, , .Status)
		If 'Status Set Status = $$$BuildErr("Error opening definition for {}", Status, ClassName) Quit Result
	}
	
	;Skip system classes, including EnsLib.* etc., if so requested.
	If ExcludeSystem, ClassNameOrObj.System Quit ""
	
	;Always return "self' prefering %String over %Library.String
	Set Result = Result_$ListBuild($$$DenormalizeClassname(ClassNameOrObj.Name))
	
	;Get superclasses; if none, we're done.
	Set Super = ClassNameOrObj.Super
	If Super = "" Quit Result
	
#if ##safeexpression($System.Version.GetMajor()>=2010)
	;From v2010 onwards, inheritance is specified in the class definition
	If ClassNameOrObj.Inheritance = "left" {
		Set From = 1, To = $Length(Super, ","), Step = 1
	} Else {
		Set From = $Length(Super, ","), To = 1, Step = -1
	}
#else
	;Before v2010 inheritance is right to left always
	Set From = $Length(Super, ","), To = 1, Step = -1
#endif
	
	;Handle superclasses, in the order determined above, recursively
	For i = From:Step:To {
		Set Name = $Piece(Super, ",", i)
		If ExcludeSystem, $Extract(Name) = "%" Continue
		Set Result = Result_..MRO(Name, ExcludeSystem, .Status)
		If 'Status Quit
	}
	If 'Status Quit Result
	
	;De-duplicate
	Set WithDuplicates = Result, Result = ""
	For i = 1:1:$ListLength(WithDuplicates) {
		Set Name = $List(WithDuplicates, i)
		If $Data(Names(Name)) Continue
		Set Result = Result_$ListBuild(Name)
		Set Names(Name) = ""
	}
	
	Quit Result
}

/// Returns the SQL variant of a classname
ClassMethod SqlName(ClassName As %String) As %String
{
	;Try CompiledClass definition:
	&sql(SELECT SqlQualifiedNameQ INTO :SqlName FROM %Dictionary.CompiledClass WHERE Name = :ClassName)
	If SQLCODE = 0 Quit SqlName
	
	;Try class definition in case the table name is specified:
	&sql(SELECT SqlTableName INTO :SqlName FROM %Dictionary.ClassDefinition WHERE Name = :ClassName)
	If SqlName = "" Set SqlName = $Piece(ClassName, ".", $Length(ClassName, "."))
	
	;Attempt quoting of strange names the same way Caché does
	If SqlName '? 1A1.AN Set SqlName = """"_SqlName_""""
	
	If $Length(ClassName, ".") > 1 {
		Set Schema = $Piece(ClassName, ".", 1, $Length(ClassName, ".") - 1)
		Set Schema = $Replace(Schema, ".", "_")
	} Else {
		Set Schema = "User"
	}
	
	Quit Schema_"."_SqlName
}

/// Renames a class definition. Optionally deletes an existing class
/// with the new name, optionally compiles the renamed class. If
/// successful, the original class is deleted.
/// Does not attempt to check any property/parameter/method return types.
ClassMethod RenameClass(From As %String, To As %String, Clear As %Boolean = 0, Compile As %Boolean = 0) As %Status
{
	; Make sure source can be opened
	Set FromDef = ##class(%Dictionary.ClassDefinition).%OpenId(From, , .sc)
	If 'sc Quit $$$BuildStatus("Error opening source class '{}'", sc, From)
	
	; Default to same package as source
	If To '[ ".", From [ "." Set To = $Piece(From, ".", 1, *-1)_"."_To
	
	; Check whether detination exists
	If ##class(%Dictionary.ClassDefinition).%ExistsId(To) {
		If 'Clear Quit $$$BuildStatus("Target class '{}' exists", , To)
		Set sc = ##class(%Dictionary.ClassDefinition).%DeleteId(To)
		If 'sc Quit $$$BuildStatus("Error deleting target class '{}'", sc, To)
	}
	
	; Copy class to new name
	#dim ToDef As %Dictionary.ClassDefinition
	Set ToDef = FromDef.%ConstructClone(1)
	Set ToDef.Name = To
	Set sc = ToDef.%Save()
	If 'sc Quit $$$BuildStatus("Error saving cloned class '{}'", sc, To)
	
	; Delete original
	Set sc = ##class(%Dictionary.ClassDefinition).%DeleteId(From)
	If 'sc Quit $$$BuildStatus("Error deleting original class '{}'", sc, From)
	
	; Compile
	If Compile {
		Set sc = $System.OBJ.Compile(To, "-duk")
		If 'sc Quit $$$BuildStatus("Error compiling target class '{}'", sc, To)
	}
	
	Quit $$$OK
}

}
