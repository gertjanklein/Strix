Class Strix.Ens.Rest.RESTServiceProjection Extends %Projection.AbstractProjection
{

/// This method creates the Ensemble Business Service class intended
/// to handle method calls in the REST class.
ClassMethod CreateProjection(ClassName As %String, ByRef Parameters As %String, Modified As %String, qstruct) As %Status
{
	If $$$defClassKeyGet(ClassName, $$$cCLASSabstract) Quit $$$OK
	
	; Are we given a %REST.Impl subclass?
	Set IsImpl = $ClassMethod(ClassName, "%IsA", "%REST.Impl")
	
	; Projection only works for REST classes
	If '$ClassMethod(ClassName, "%IsA", "%CSP.REST"), 'IsImpl {
		Quit ..BuildStatus("Class {} is not a %CSP.REST.",,ClassName)
	}
	
	; Determine the name of the service class to create
	Set ServiceClassName = $Parameter(ClassName, "ServiceClassName")
	If ServiceClassName = "" Set ServiceClassName = ClassName_".Service"
	
	; Determine the target methods (as specified in UrlMap)
	Set sc = ..GetMethods(ClassName, .Methods)
	If 'sc Quit ..BuildStatus("Error determining calls in {}:", sc, ServiceClassName)
	If '$ListLength(Methods) Quit $$$OK ; No methods yet
	
	; Create/open service class definition
	If ##class(%Dictionary.ClassDefinition).%ExistsId(ServiceClassName) {
		Set ClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(ServiceClassName, , .sc)
		If 'sc Quit ..BuildStatus("Error opening definition of {}:", sc, ServiceClassName)
	} Else {
		Set ClassDef = ##class(%Dictionary.ClassDefinition).%New(ServiceClassName, 25)
	}
	Set ClassDef.Super = "Strix.Ens.Rest.BusinessService"
	; Don't show class as generated, default tooling will not place it in source control
	Do ClassDef.GeneratedByReset()
	Set ClassDef.Description = "Generated for "_ClassName_"; do not edit."
	
	; Add methods and associated settings to the service class
	For i = 1:1:$ListLength(Methods) {
		Set MethodName = $List(Methods, i)
		Set sc = ..HandleMethod(ClassName, MethodName, ClassDef)
		If 'sc Return ..BuildStatus("Error handling method {} ({}):", sc, i, MethodName)
	}
	
	; Save class definition
	Set sc = ClassDef.%Save()
	If 'sc Quit ..BuildStatus("Error creating/updating service class:", sc)
	
	; Queue for compilation
	Do ..QueueClass(ServiceClassName)
	
	Quit $$$OK
}

/// Creates code and settings for one single REST method.
ClassMethod HandleMethod(ClassName As %String, MethodName As %String, SvcClassDef As %Dictionary.ClassDefinition, IsImpl As %Boolean) As %Status
{
	; == Property for target specification
	
	Set TargetPropName = MethodName_"Target"
	#dim SvcProp As %Dictionary.PropertyDefinition
	Set SvcProp = ##class(Strix.Generator.Utilities).GetInCollection(SvcClassDef.Properties, TargetPropName, 1, .sc)
	If 'sc Quit ..BuildStatus("Error finding/creating property {}:", sc, TargetPropName)
	Set SvcProp.Type = "Ens.DataType.ConfigName"
	Set SvcProp.Description = "Target config name for REST method "_MethodName_"."
	
	
	; == Setting for target specification
	
	#dim SvcParm As %Dictionary.ParameterDefinition
	Set SvcParm = ##class(Strix.Generator.Utilities).GetInCollection(SvcClassDef.Parameters, "SETTINGS", 1, .sc)
	If 'sc Quit ..BuildStatus("Error finding/creating SETTINGS parameter:", sc)
	
	Set Value = SvcParm.Default, Found = 0
	For i = 1:1:$Length(Value, ",") {
		Set Spec = $Piece(Value, ",", i)
		If $Piece(Spec, ":") '= TargetPropName Continue
		Set $Piece(Value, ",", i) = TargetPropName_":Basic"
		Set Found = 1
	}
	If 'Found Set Value = $Select(Value '= "": Value_",", 1:"")_TargetPropName_":Basic"
	
	Set SvcParm.Default = Value
	
	
	; == Dispatcher method
	
	#dim SvcMethod As %Dictionary.MethodDefinition
	Set SvcMethod = ##class(Strix.Generator.Utilities).GetInCollection(SvcClassDef.Methods, MethodName, 1, .sc)
	If 'sc Quit ..BuildStatus("Error finding/creating method {}:", sc, MethodName)
	
	Do SvcMethod.Implementation.Clear()
	#define W(%s) Do SvcMethod.Implementation.WriteLine($Char(9)_(%s))
	
	; CSPRequest holds most data from %request
	$$$W("Set Req = ##class(Strix.Ens.Rest.RESTRequest).%New()")
	$$$W("Set Req.MethodName = """_MethodName_"""")
	
	; Place REST call parsed (method) parameters in MethodParameters array
	; ParsedSpec is list of $lb(Name,Type,I/O,Default)
	Set ParsedSpec = $$$comMemberKeyGet(ClassName, $$$cCLASSmethod, MethodName, $$$cMETHformalspecparsed)
	Set Spec = ""
	For i = 1:1:$ListLength(ParsedSpec) {
		Set Item = $List(ParsedSpec, i), Name = $List(Item, 1), Type = $List(Item, 2)
		If i > 1 Set Spec = Spec_","
		Set Spec = Spec_Name
		If Type '= "" Set Spec = Spec_":"_$$$DenormalizeClassname(Type)
		$$$W("If $Data("_Name_", Value)#2 Do Req.MethodParameters.SetAt(Value, """_Name_""")")
	}

	; Method parameter list and return type
	Set SvcMethod.FormalSpec = Spec
	Set SvcMethod.ReturnType = "%Status"

	; Description
	Set Desc = "Generated method for "_ClassName_":"_MethodName
	Set CurDesc = $$$defMemberKeyGet(ClassName, $$$cCLASSmethod, MethodName, $$$cMETHdescription)
	If CurDesc '= "" Set Desc = Desc_"; description:"_$$$EOL_CurDesc
	Set SvcMethod.Description = Desc

	; Code to call the target through the inherited SendRequest method
	$$$W("Set sc = ..SendRequest(.."_TargetPropName_", Req, .Rsp)")
	$$$W("If 'sc Quit sc")
	$$$W("Quit $$$OK")


	Quit $$$OK
}

/// Retrieves a list of methods in classname that are referred to in
/// the class's UrlMap.
ClassMethod GetMethods(ClassName As %String, Output Methods As %List) As %Status
{
	Set Methods = ""
	
	Set Allowed = $Parameter(ClassName, "Methods")
	If Allowed '= "*" Set Allowed = $ListFromString(Allowed)
	
	; Determine the class containing the URL dispatcher XData block
	Set DispClass = ClassName
	If $ClassMethod(ClassName, "%IsA", "%REST.Impl") Set $Piece(DispClass, ".", *) = "disp"
	
	Set XDataName = DispClass_"||UrlMap"
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(XDataName, , .sc)
	If 'sc Quit ..BuildStatus("Error opening UrlMap in {}:", sc, XDataName)
	
	#dim Doc As EnsLib.EDI.XML.Document
	Set Doc = ##class(EnsLib.EDI.XML.Document).ImportFromLibraryStream(XData.Data, .sc)
	If 'sc Quit ..BuildStatus("Error parsing UrlMap in {}:", sc, XDataName)
	
	For i = 1:1:Doc.GetValueAt("/Routes/Route[*]") {
		Set Method = Doc.GetValueAt("/Routes/Route["_i_"]/@Call", "", .sc)
		If 'sc Return ..BuildStatus("Error retrieving Route {} in {}:", sc, i, XDataName)
		; Skip this method if not listed
		If Allowed '= "*", '$ListFind(Allowed, Method) Continue
		Set Methods = Methods_$lb(Method)
	}
	
	Quit $$$OK
}

// =====

/// Generates code for a call to the service. For this to work,
/// the code that calls this method mus be a generator method.
/// (Codemode objectgenerator causes a #6301: SAX XML Parser Error
/// in method %CSP.REST:SupportedVerbs under some circumstances,
/// and can't be used.)
ClassMethod GenerateCall() As %Status
{
	; If we don't check here, the code below would silently do nothing.
	If $IsObject(%code) Quit $$$ERROR($$$GeneralError, "Call this method with codemode 'generator', not 'objectgenerator'.")
	
	Set ClassName = %classname
	Set MethodName = %method
	
	Set ServiceName = $Get(%parameter("ServiceName"))
	If ServiceName = "" Quit $$$ERROR($$$GeneralError, "Parameter ServiceName required.")
	
	; Code to create the business service
	#define W(%s) Set %code($Increment(%code))=$Char(9)_(%s)
	$$$W("Set sc = ##class(Ens.Director).CreateBusinessService("""_ServiceName_""", .Service)")
	$$$W("If 'sc Quit ..HandleError("""_MethodName_""",sc,""Error creating business service '"_ServiceName_"'"")")
	
	; Create call parameter list. Call ByRef in case parameter not present.
	Set ParmList = ""
	Set Spec = $$$comMemberKeyGet(ClassName, $$$cCLASSmethod, MethodName, $$$cMETHformalspecparsed)
	For i = 1:1:$ll(Spec) {
		Set Name = $List($List(Spec, i))
		If i > 1 Set ParmList = ParmList_", "
		Set ParmList = ParmList_"."_Name
	}
	
	; Call the generated service method
	$$$W("Set sc = Service."_MethodName_"("_ParmList_")")
	$$$W("If 'sc Quit ..HandleError("""_MethodName_""",sc,""Error returned from business service '"_ServiceName_"'"")")
	
	$$$W("Quit $$$OK")
	
	Quit $$$OK
}

// =====

ClassMethod BuildStatus(Message, Status, Parms...) As %Status
{
	For i = 1:1:$Get(Parms) {
		Set Message = $Replace(Message, "{}", $Get(Parms(i)),, 1)
	}
	Set MsgStatus = $$$ERROR($$$GeneralError, Message)
	If $Get(Status) '= "", 'Status Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	Quit MsgStatus
}

}
