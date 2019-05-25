<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.CSV.Writer">
<Abstract>1</Abstract>
<IncludeCode>Strix</IncludeCode>
<IncludeGenerator>Strix</IncludeGenerator>
<PropertyClass>Strix.CSV.PropertyParm</PropertyClass>
<TimeCreated>65153,70175.250605</TimeCreated>

<Parameter name="CSVSeparator">
<Description>
Separator to use on output</Description>
<Default>,</Default>
</Parameter>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="CSVGetHeaderRow">
<Description>
Returns the header row, consisting of the property names or
the strings specified by property parameter CsvColumnHeader.</Description>
<ClassMethod>1</ClassMethod>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Result = ""
	Set ColumnList = ..CSVGetInfo()
	For i = 1:1:$ListLength(ColumnList) {
		Set Item = $List(ColumnList, i)
		Set Name = $List(Item, 2)
		If Name = "" Set Name = $List(Item, 1)
		If i > 1 Set Result = Result_..#CSVSeparator
		Set Name = ..CSVEscape(Name)
		Set Result = Result_Name
	}
	Quit Result
]]></Implementation>
</Method>

<Method name="CSVGetRow">
<Description>
Returns the CSV for this object.</Description>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set ColumnList = ..CSVGetInfo()
	For i = 1:1:$ListLength(ColumnList) {
		Set Column = $List(ColumnList, i)
		Set Property = $List(Column, 1), ColumnName = $List(Column, 2), DataType = $List(Column, 3)
		If ColumnName = "" Set ColumnName = Property
		Set Value = $Property($this, Property)
		Set Value = ..CSVDataTypeOut(Property, ColumnName, DataType, Value)
		Set Values(Property) = Value
	}
	
	; Callback for class- or object-specific fixups
	Do ..CSVUpdateRow(.Values)
	
	Set Result = ""
	For i = 1:1:$ListLength(ColumnList) {
		Set Column = $List(ColumnList, i)
		Set Property = $List(Column, 1)
		If i > 1 Set Result = Result_..#CSVSeparator
		Set Result = Result_..CSVEscape(Values(Property))
	}
	
	Quit Result
]]></Implementation>
</Method>

<Method name="CSVEscape">
<Description>
Escapes a value, by surrounding it with quotes, if needed:
if a quote, the separator character, or cr/lf are present.
Quotes inside a quoted value are escaped by doubling them.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Value:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	If (Value [ """")
	   || (Value [ ..#CSVSeparator)
	   || (Value [ $Char(13))
	   || (Value [ $Char(10)) {
		Quit """"_$Replace(Value, """", """""")_""""
	}
	Quit Value
]]></Implementation>
</Method>

<Method name="CSVDataTypeOut">
<Description>
Datatype conversion callback. Receives property name, column name,
datatype, and value. Expected to return the converted value.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Name:%String,ColumnName:%String,Type:%String,Value:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	If Value = "" Quit ""
	
	If Type = "%Date" Quit $ZDate(Value, 3)
	If Type = "%Time" Quit $ZTime(Value, 1)
	If Type = "%TimeStamp" Quit $Translate($ZDateTime(Value, 3, 1), " ", "T")
	
	Quit Value
]]></Implementation>
</Method>

<Method name="CSVUpdateRow">
<Description>
Generic callback for updates to a row before it is being output.
Receives data keyed on property name, after datatype conversion.</Description>
<FormalSpec><![CDATA[&RowData:%String]]></FormalSpec>
<Implementation><![CDATA[	Quit
]]></Implementation>
</Method>

<Method name="CSVGetInfo">
<Description>
Helper: returns CSV column info</Description>
<ClassMethod>1</ClassMethod>
<CodeMode>objectgenerator</CodeMode>
<Private>1</Private>
<ReturnType>%List</ReturnType>
<Implementation><![CDATA[
	#dim Properties As %Collection.AbstractList
	Set Properties = ##class(Strix.Generator.Utilities).GetOrderedList(%compiledclass.Properties, .sc)
	If 'sc Quit $$$BuildStatus("Error retrieving property list for class {}:", sc, %class.Name)
	
	Set Names = ""
	For i = 1:1:Properties.Count() {
		#dim pd As %Dictionary.CompiledProperty
		Set pd = Properties.GetAt(i)
		
		; Skip this property, if so requested
		If 'pd.Parameters.GetAt("CsvInclude") Continue
		
		; Skip internal properties
		If pd.Internal Continue
		
		; Skip system properties
		Set Name = pd.Name
		If $Extract(Name) = "%" Continue
		
		Set ColumnName = pd.Parameters.GetAt("CsvColumnHeader")
		; If column name is equal to property name or empty, use property name
		If ColumnName = Name Set ColumnName = ""
		Set Type = $$$DenormalizeClassname(pd.Type)
		
		If Names '= "" Set Names = Names_","
		Set Names = Names_"$lb("""_pd.Name_""","""_$Replace(ColumnName, """", """""")_""","""_Type_""")"
	}
	
	If Names '= "" {
		Do %code.WriteLine($Char(9)_"Quit $lb("_Names_")")
	} Else {
		Do %code.WriteLine($Char(9)_"Quit """"")
	}
	
	Quit $$$OK
]]></Implementation>
</Method>
</Class>
</Export>
