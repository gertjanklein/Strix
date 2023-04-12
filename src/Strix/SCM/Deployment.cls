Include %occErrors

/// Helper code for managing Caché export files.
Class Strix.SCM.Deployment Extends %RegisteredObject
{

/// Scratch data
Property ClassesInRelease As %String [ MultiDimensional ];

/// Scratch data
Property PackagesInRelease As %String [ MultiDimensional ];

// =====

/// Determines the packages in a release file, and searches for
/// classes present on this system that are not present in the
/// release file. Optionally deletes them.
/// Matching of redundant classes is only done in packages for
/// which classes exist in the release.
ClassMethod FindRedundantClassesInExport(ReleaseFileName As %String, Delete As %Boolean = 0)
{
	Set Me = ..%New()
	Set Status = Me.FindRedundantClassesInExportImp(ReleaseFileName, Delete)
	If 'Status Do $System.Status.DisplayError(Status)
	Quit
}

/// Determines the packages in export files in a directory, and
/// searches for classes present on this system that are not present
/// in the export files. Optionally deletes them.
/// Matching of redundant classes is only done in packages for
/// which classes exist in the release.
ClassMethod FindRedundantClassesInDir(Directory As %String, Delete As %Boolean = 0)
{
	Set Me = ..%New()
	Set Status = Me.FindRedundantClassesInDirImp(Directory, Delete)
	If 'Status Do $System.Status.DisplayError(Status)
	Quit
}

// =====

/// Implementation of FindRedundantClassesInExport.
Method FindRedundantClassesInExportImp(ReleaseFileName As %String, Delete As %Boolean = 0) As %Status
{
	Set Status = ..GetClassesInExportFile(ReleaseFileName)
	If 'Status Quit ..BuildStatus("Error determining classes in release file:", Status)
	
	Set Package = ""
	For  {
		Set Package = $Order(..PackagesInRelease(Package))
		If Package = "" Quit
		
		Set Status = ..CheckPackage(Package, .UnknownClasses)
		If 'Status Return ..BuildStatus("Error checking package "_Package_":", Status)
	}
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(UnknownClasses(ClassName))
		If ClassName = "" Quit
		Write "Redundant class: "_ClassName,!
		If 'Delete Continue
		Set Status = $System.OBJ.Delete(ClassName, "d")
		If 'Status Return ..BuildStatus("Error deleting class {}", Status, ClassName)
	}
	
	Quit $$$OK
}

/// Implementation of FindRedundantClassesInDir.
Method FindRedundantClassesInDirImp(Directory As %String, Delete As %Boolean = 0) As %Status
{
	Set rs = ##class(%ResultSet).%New("%File:FileSet")
	Set Status = rs.Execute(Directory, "*.xml")
	If 'Status Quit ..BuildStatus("Error listing contents of '{}'", Status, Directory)
	
	While rs.Next() {
		Set FilePath = rs.Get("Name"), Name = rs.Get("ItemName")
		Set Status = ..GetClassesInExportFile(FilePath)
		If 'Status Return ..BuildStatus("Error determining classes in file '{}':", Status, FilePath)
	}
	
	Set Package = ""
	For  {
		Set Package = $Order(..PackagesInRelease(Package))
		If Package = "" Quit
		
		Set Status = ..CheckPackage(Package, .UnknownClasses)
		If 'Status Return ..BuildStatus("Error checking package "_Package_":", Status)
	}
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(UnknownClasses(ClassName))
		If ClassName = "" Quit
		Write "Redundant class: "_ClassName,!
		If 'Delete Continue
		Set Status = $System.OBJ.Delete(ClassName, "d")
		If 'Status Return ..BuildStatus("Error deleting class {}", Status, ClassName)
	}
	
	Quit $$$OK
}

/// Find classes in a package not present in ..ClassesInRelease.
Method CheckPackage(Package As %String, Output UnknownClasses As %String) As %Status
{
	Set Status = $System.OBJ.GetPackageList(.Classes, Package, "")
	If 'Status Quit Status
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Classes(ClassName))
		If ClassName = "" Quit
		
		;Skip if exists in deployment
		If $Data(..ClassesInRelease(ClassName)) Continue
		
		;Skip generated classes like Xxx.Thread1
		If ..IsGenerated(ClassName) Continue
		
		;Ok, we really don't know this one
		Set UnknownClasses(ClassName) = ""
	}
	
	Quit $$$OK
}

/// Checks if a class is generated.
Method IsGenerated(ClassName As %String) As %Boolean
{
	&sql(SELECT GeneratedBy INTO :GeneratedBy
	       FROM %Dictionary.ClassDefinition
	      WHERE Name = :ClassName)
	If SQLCODE Quit 0
	If GeneratedBy '= "" Quit 1
	Quit 0
}

// -----

/// Returns an array of all items in an export; the export may
/// be a stream or a filename. Filter can contain a comma-separated
/// list of item types to return (e.g. "cls" or "mac,inc").
/// Returns items indexed as an array mapping name to type. If
/// more than one type has the same name, the value is a comma
/// separated list of those types. E.g., normally:
///   Items("The.Class.Name")="cls"
/// but perhaps:
///   Items("The.Class.Name")="cls,inc"
/// if an include file with the same name is present.
ClassMethod GetItemsInExport(Export, Filter As %String = "", Output Items As %String) As %Status
{
	;Get list of items in export
	If $IsObject(Export) {
		;Object: assume a stream
		Set Status = $System.OBJ.LoadStream(Export, "-d", , .InExport, 1)
		If 'Status Quit ..BuildStatus("Error loading stream as export:", Status)
	} Else {
		;String: assume a filename
		Set Status = $System.OBJ.Load(Export, "-d", , .InExport, 1)
		If 'Status Quit ..BuildStatus("Error loading file '{}' as export:", Status, Export)
	}
	
	;Convert filter to list, unless it already is one
	If '$ListValid(Filter) Set Filter = $ListFromString(Filter)
	
	;Loop through items, stripping type and applying filter
	Set Item = ""
	For  {
		Set Item = $Order(InExport(Item))
		If Item = "" Quit
		
		Set Type = $ZConvert($Piece(Item, ".", *), "l")
		If $ListLength(Filter), '$ListFind(Filter, Type) Continue
		
		Set Name = $Piece(Item, ".", 1, *-1)
		
		If $Data(Items(Name), Current) {
			Set Items(Name) = Current_","_Type
		} Else {
			Set Items(Name) = Type
		}
	}
	
	Quit $$$OK
}

Method GetClassesInExportFile(ExportFileName As %String) As %Status
{
	Set Status = ..GetItemsInExport(ExportFileName, "cls", .Items)
	If 'Status Quit ..BuildStatus("Error determining export file contents:", Status)
	
	Set ClassName = ""
	For  {
		Set ClassName = $Order(Items(ClassName))
		If ClassName = "" Quit
		
		;Store classname
		Set ..ClassesInRelease(ClassName) = ""
		
		;Get and store package
		Set Package = $Piece(ClassName, ".", 1, *-1)
		Set ..PackagesInRelease(Package) = ""
	}
	
	Quit $$$OK
}

// =====

/// Extract the (XML) contents from a Caché XML export file, i.e.
/// everything inside the Export element.
ClassMethod GetExportContents(Export As %Stream, Output Content As %Stream) As %Status
{
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(..%ClassName(1)_"||ExtractAllFromExport", , .Status)
	If 'Status Quit ..BuildStatus("Error opening XData definition:", Status)
	
	Set Status = ##class(%XML.XSLT.Transformer).TransformStream(Export, XData.Data, .Content)
	If 'Status Quit ..BuildStatus("Error in transform:", Status)
	
	Quit $$$OK
}

/// Combines the contents of the XML export files passed in by name,
/// by extracting everything within the Export elements, and placing
/// it into a combined export element. Uses the Caché version of the
/// first export file for the combined one.
ClassMethod CombineExportFiles(FileNames As %String, Output Combined As %Stream) As %Status
{
	; Get the XSL to extract the contents of an export file
	Set XData = ##class(%Dictionary.XDataDefinition).%OpenId(..%ClassName(1)_"||ExtractAllFromExport", , .Status)
	If 'Status Quit ..BuildStatus("Error opening XData definition:", Status)
	
	; Create stream if not passed in
	If '$IsObject($Get(Combined)) Set Combined = ##class(%GlobalBinaryStream).%New()
	
	; Loop through files
	Set FileName = ""
	For Nr = 1:1 {
		Set FileName = $Order(FileNames(FileName))
		If FileName = "" Quit
		
		; Get stream for file
		Set Export = ##class(%FileBinaryStream).%New()
		Set Status = Export.LinkToFile(FileName)
		If 'Status Set Status = ..BuildStatus("Error linking to file '{}':", Status, FileName)
		
		; Use first file for copying the XMl declaration and opening Export element
		If Nr = 1 {
			; XML declaration
			Do Combined.WriteLine(Export.ReadLine())
			; Export element; replace timestamp with "now"
			Set Line = Export.ReadLine()
			Set Index = $Find(Line, "ts=""")
			If Index Set $Extract(Line, Index, Index+18) = $ZDateTime($Horolog, 3, 1)
			Do Combined.Write(Line)
			Do Export.Rewind()
			
		} Else {
			; Rewind XSL for second and subsequent files
			Do XData.Data.Rewind()
			
		}
		
		; Add comment with originating file
		Do Combined.WriteLine($$$EOL_"<!-- "_$ZConvert(##class(%File).GetFilename(FileName), "O", "XML")_" -->")
			
		Set Status = ##class(%XML.XSLT.Transformer).TransformStream(Export, XData.Data, .Combined)
		If 'Status Set Status = ..BuildStatus("Error in transform:", Status) Quit
		
		Write "Processed "_FileName,!
	}
	If 'Status Quit Status
	
	Do Combined.WriteLine("</Export>")
	
	Quit $$$OK
}

// =====

/// Build a %Status from a message and a %Status, optionally replacing
/// placeholders with values passed in.
ClassMethod BuildStatus(Message As %String, Status As %Status = "", Args... As %String) As %Status
{
	;Replace placeholders with content, if present
	Set Index = 0
	For Count = 1:1 {
		Set Index = $Find(Message, "{}", Index)
		If Index = 0 Quit
		
		Set Value = $Get(Args(Count))
		Set $Extract(Message, Index-2, Index-1) = Value
		Set Index = Index + $Length(Value) - 2
	}
	
	;Convert message to %Status
	Set MsgStatus = $System.Status.Error($$$GeneralError, Message)
	
	;Append status from parameter, if specified
	If Status '= "" Set MsgStatus = $System.Status.AppendStatus(MsgStatus, Status)
	
	Quit MsgStatus
}

// =====

/// XSL to extract the contents of a Caché XML export file.
XData ExtractAllFromExport
{
<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
    <xsl:copy-of select="//Export/*"/>
</xsl:template>
</xsl:stylesheet>
}

}
