Class Strix.XML.WSDLReader Extends %SOAP.WSDL.Reader
{

/// Overridden method from superclass. When passing in an existing schema
/// reader, the overridden code clears the class prefix. This does not
/// happen when the reader is created locally.
/// This method copies the code from the superclass, and removes the
/// undesired behaviour.
Method SetupSchemaReader(pPackage As %String, schemaReader As %XML.Utils.SchemaReader) As %Status [ CodeMode = objectgenerator ]
{
	Set Code = ##class(%Dictionary.MethodDefinition).%OpenId("%SOAP.WSDL.Reader||SetupSchemaReader").Implementation.Read()
	Set Code = $Replace(Code, "Set ..SchemaReader.ClassPrefix = """"", "Set ..SchemaReader.ClassPrefix = pPackage")
	Set Code = $Replace(Code, "Set ..SchemaReader.NoClassPrefix=(pPackage'="""")", ";Set ..SchemaReader.NoClassPrefix=(pPackage'="""")")
	Do %code.Write(Code)
	Quit $$$OK
}

}

