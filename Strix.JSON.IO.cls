<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
<Class name="Strix.JSON.IO">
<IncludeCode>Strix</IncludeCode>
<Super>%RegisteredObject</Super>
<TimeCreated>64395,34993.066133</TimeCreated>

<Method name="JSONExport">
<Description>
Creates a %DynamicObject for the Caché object passed in. The Caché
object is expected be a subclass of Strix.JSON.Adaptor.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Object:Strix.JSON.Adaptor,Sparse:%Boolean=0,Spec:%String="",*Status:%Status</FormalSpec>
<ReturnType>%DynamicObject</ReturnType>
<Implementation><![CDATA[
	Set Result = {}, Status = $$$OK
	
	; Get class-level and runtime I/O specs
	Do ..GetSpec(Spec, Object.%GetParameter("JSONSpec"), .Specs)
	
	Do Object.GetPropertyInfo(.InfoArray)
	For i = 1:1:InfoArray {
		;Name, JSON name, JSONIO, Type, Collection, IsDatatype, IsStream, IsRelationship, IsAdaptor, IsJSONProp
		Set PropInfo = InfoArray(i)
		
		Set JSONIO = $List(PropInfo, 3)
		If JSONIO = "IN" Continue
		
		Set Name = $List(PropInfo, 1)
		Set JSONName = $List(PropInfo, 2)
		
		Set Collection = $List(PropInfo, 5)
		Set IsRelationship = $List(PropInfo, 8)
		
		If Collection = "list" || IsRelationship {
			Set List = $ZObjProperty(Object, Name)
			Set Status = ..ListOut(PropInfo, Sparse, List, .JSONList)
			If 'Status Return Result
			If JSONList '= "" Do Result.%Set(JSONName, JSONList)
			Continue
		}
		
		If Collection = "array" {
			Set Array = $ZObjProperty(Object, Name)
			Set Status = ..ArrayOut(PropInfo, Sparse, List, .JSONObject)
			If 'Status Return Result
			If JSONObject '= "" Do Result.%Set(JSONName, JSONObject)
			Continue
			
		}
		
		Set Type = $List(PropInfo, 4)
		Set IsDatatype = $List(PropInfo, 6)
		Set IsStream = $List(PropInfo, 7)
		Set IsJSONProp = $List(PropInfo, 10)
		
		If IsJSONProp {
			Set Value = $ZObjMethod(Object, Name_"AsObject")
			Do Result.%Set(JSONName, Value)
			Continue
		}
		
		Set Value = $ZObjProperty(Object, Name)
		If IsDatatype {
			Set Value = ..ValueOut(Value, Type, .JSONType)
			If Sparse, Value = "" Continue
			Do Result.%Set(JSONName, Value, JSONType)
			
		} ElseIf IsStream {
			Set Value = Value.Read()
			If Sparse, Value = "" Continue
			Do Result.%Set(JSONName, Value, "string")
			
		} ElseIf $IsObject(Value) {
			Set Value = Value.JSONExport(Sparse, Spec, .Status)
			If 'Status Return $$$BuildErr("Error handling subobject {} of type {}:", Status, Name, Type)
			If Sparse, Value = "" Continue
			Do Result.%Set(JSONName, Value)
			
		}
	}
	
	Quit Result
]]></Implementation>
</Method>

<Method name="JSONImport">
<Description>
Loads data in a Caché object from a %DynamicObject. The Caché
object is expected be a subclass of Strix.JSON.Adaptor.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Object:Strix.JSON.Adaptor,Data:%DynamicObject,Spec:%String=""</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Set ClassName = Object.%ClassName(1)
	
	; Get class-level and runtime I/O specs
	Do ..GetSpec(Spec, Object.%GetParameter("JSONSpec"), .Specs)
	
	Do Object.GetPropertyInfo(.InfoArray)
	For i = 1:1:InfoArray {
		;Name, JSON name, JSONIO, Type, Collection, IsDatatype, IsStream, IsRelationship, IsAdaptor
		Set PropInfo = InfoArray(i)
		
		Set JSONIO = $List(PropInfo, 3)
		If (JSONIO = "OUT") || (JSONIO = "CALC") Continue
		
		Set JSONName = $List(PropInfo, 2)
		If 'Data.%IsDefined(JSONName) Continue
		
		Set Name = $List(PropInfo, 1)
		Set Collection = $List(PropInfo, 5)
		
		If Collection '= "" {
			Set Property = $ZObjProperty(Object, Name)
			Set JSONObj = Data.%Get(JSONName)
			Set JSONType = Data.%GetTypeOf(JSONName)
			
			If Collection = "list" {
				If JSONType '= "array" {
					Return $$$BuildErr("Error handling property {}: expected JSON array, got {}", , Name, JSONType)
				}
				Set Status = ..ListIn(ClassName, PropInfo, Property, JSONObj)
				
			} ElseIf Collection = "array" {
				If JSONType '= "object" {
					Return $$$BuildErr("Error handling property {}: expected JSON object, got {}", , Name, JSONType)
				}
				Set Status = ..ArrayIn(ClassName, PropInfo, Property, JSONObj)
				
			}
			If 'Status Return $$$BuildErr("Error handling {} property {}", Status, Collection, Name)
			
			Continue
		}
		
		;----- Single value
		
		Set Type = $List(PropInfo, 4)
		Set IsDatatype = $List(PropInfo, 6)
		Set IsStream = $List(PropInfo, 7)
		Set IsJSONProp = $List(PropInfo, 10)
		
		Set Value = Data.%Get(JSONName)
		Set JSONType = Data.%GetTypeOf(JSONName)
		
		If IsDatatype {
			Set Value = ..ValueIn(ClassName, PropInfo, Value, .Status)
			If 'Status Return Status
			Set $ZObjProperty(Object, Name) = Value
			
		} ElseIf IsJSONProp {
			Set $ZObjProperty(Object, Name) = Value
			
		} ElseIf IsStream {
			Set Stream = $ZobjProperty(Object, Name)
			Do Stream.%Write(Value)
			
		} Else {
			Set ObjectProp = $ZObjProperty(Object, Name)
			If ObjectProp = "" {
				Set $ZObjProperty(Object, Name) = $ZObjClassMethod(Type, "CreateFromJSON", Value, , .Status)
				If 'Status Return $$$BuildErr("Error handling sub-object {} of type {}:", Status, Name, Type)
				
			} Else {
				Set Status = ObjectProp.JSONImport(Value)
				If 'Status Return $$$BuildErr("Error handling sub-object {} of type {}:", Status, Name, Type)
				
			}
			
		}
	}
	
	Quit $$$OK
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="GetSpec">
<Description>
Gets JSON I/O specifications.
Merges them from two locations: the object parameter and
a runtime override. Returns the data as an array, indexed
by name, in output parameter ByName.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Override:%String,FromObject:%String,*ByName:%String</FormalSpec>
<Implementation><![CDATA[
	If FromObject '= "", Override '= "" {
		Set Specs = FromObject_","_Override
	} Else {
		Set Specs = FromObject_Override
	}
	If Specs = "" Quit
	
	For i = 1:1:$Length(Specs, ",") {
		Set Item = $Piece(Specs, ",", i)
		Set Name = $Piece(Item, ":", 1)
		Set Spec = $Piece(Item, ":", 2, *)
		Set ByName(Name) = Spec
	}
	
	Quit
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="ListIn">
<Description>
Loads items from the %DynamicArray (JSON list) into the Caché list.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>ClassName:%String="",PropInfo:%List,List:%AbstractList,Data:%DynamicArray</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Do List.Clear()
	Set it = Data.%GetIterator()
	
	;Name, JSON name, JSONIO, Type, Collection, IsDatatype, IsStream, IsRelationship, IsAdaptor
	Set Type = $List(PropInfo, 4)
	Set IsDatatype = $List(PropInfo, 6)
	Set IsStream = $List(PropInfo, 7)
	
	While it.%GetNext(.Key, .Value) {
		If IsDatatype {
			Set Value = ..ValueIn(ClassName, PropInfo, Value, .Status)
			If 'Status Return Status
			Set Status =  List.Insert(Value)
			
		} ElseIf IsStream {
			Set Stream = $ZObjClassMethod(Type, "%New")
			Do Stream.Write(Value)
			Set Status = List.Insert(Stream)
			
		} Else {
			Set ObjectProp = $ZObjClassMethod(Type, "CreateFromJSON", Value, , .Status)
			If 'Status Return $$$BuildErr("Error handling sub-object {} of type {}:", Status, Key, Type)
			Set Status = List.Insert(ObjectProp)
			
		}
		If 'Status Return Status
	}
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ArrayIn">
<Description>
Loads items from the %DynamicObject (JSON object) into the Caché array. The
%DynamicObject property name is used as the Caché array key.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>ClassName:%String,PropInfo:%List,Array:%AbstractArray,Data:%DynamicObject</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	Do Array.Clear()
	Set it = Data.%GetIterator()
	
	Set Type = $List(PropInfo, 4)
	Set IsDatatype = $List(PropInfo, 6)
	Set IsStream = $List(PropInfo, 7)
	
	While it.%GetNext(.Key, .Value) {
		If IsDatatype {
			Set Value = ..ValueIn(ClassName, PropInfo, Value, .Status)
			If 'Status Return Status
			Set Status = Array.SetAt(Value, Key)
			
		} ElseIf IsStream {
			Set Stream = $ZObjClassMethod(Type, "%New")
			Do Stream.Write(Value)
			Set Status = Array.SetAt(Value, Key)
			
		} Else {
			Set ObjectProp = $ZObjClassMethod(Type, "CreateFromJSON", Value, , .Status)
			If 'Status Return $$$BuildErr("Error handling sub-object {} of type {}:", Status, Name, Type)
			Set Status = Array.SetAt(Value, Key)
			
		}
		If 'Status Return Status
	}
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ValueIn">
<Description>
Converts, if necessary, a value retrieved from a %DynamicObject to the
appropriate Caché value, and checks whether it is valid for the Caché datatype.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>ClassName:%String="",PropInfo:%List,Value:%String,*Status:%Status</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set Status = $$$OK
	If Value = "" Quit ""
	
	Set Type = $List(PropInfo, 4)
	
	If "%Date, %TimeStamp, %Time" [ Type {
		;The name of the class is used to support property parameters like MINVAL.
		;If it is unavailable, use the datatypes default.
		If ClassName = "" {
			Set ClassName = Type, Name = ""
		} Else {
			Set Name = $List(PropInfo, 1)
		}
		
		;Convert from external to internal format. For external format we use
		;the XSD format, (a subset of) ISO 8601.
		Set Result = $ZObjClassmethod(ClassName, Name_"XSDToLogical", Value)
		If Result = "" Set Status = $$$BuildErr("Datatype conversion failed for property {} with value {}",, Name, Value) Quit ""
		
		Set Status = $ZObjClassmethod(ClassName, Name_"IsValid", Result)
		If 'Status Set Status = $$$BuildErr("Invalid value for property {}: {}", Status, Name, Value) Quit ""
		
		Quit Result
	}
	
	Quit Value
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
// =====

]]></Content>
</UDLText>

<Method name="ListOut">
<Description>
Places items in the Caché list into a %DynamicArray.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>PropInfo:%List,Sparse:%Boolean,List:%AbstractList,*Data:%DynamicArray</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	If Sparse, 'List.Count() Set Data = "" Quit $$$OK
	
	Set Data = []
	
	Set Type = $List(PropInfo, 4)
	Set IsDatatype = $List(PropInfo, 6)
	Set IsStream = $List(PropInfo, 7)
	
	For i = 1:1:List.Count() {
		Set Value = List.GetAt(i)
		
		If IsDatatype {
			Set Value = ..ValueOut(Value, Type, .JSONType)
			Do Data.%Push(Value, JSONType)
			
		} ElseIf IsStream {
			Set Value = Value.Read()
			Do Data.%Push(Value, "string")
			
		} Else {
			Set Value = Value.JSONExport(Sparse, , .Status)
			If 'Status Return $$$BuildErr("Error handling object at index {} of type {}:", Status, i, Type)
			Do Data.%Push(Value)
			
		}
	}
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ArrayOut">
<Description>
Places items in the Caché array into a %DynamicObject; the caché key will
be used as the property name.</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>PropInfo:%List,Sparse:%Boolean,Array:%AbstractArray,*Data:%DynamicObject</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	If Sparse, 'Array.Count() Set Data = "" Quit $$$OK
	
	Set Data = {}
	
	Set Type = $List(PropInfo, 4)
	Set IsDatatype = $List(PropInfo, 6)
	Set IsStream = $List(PropInfo, 7)
	
	Set Key = ""
	For  {
		Set Value = Array.GetNext(.Key)
		
		If IsDatatype {
			Set Value = ..ValueOut(Value, Type, .JSONType)
			If Sparse, Value = "" Continue
			Do Data.%Set(Key, Value, JSONType)
			
		} ElseIf IsStream {
			Set Value = Value.Read()
			If Sparse, Value = "" Continue
			Do Data.%Set(Key, Value, "string")
			
		} Else {
			Set Value = Value.JSONExport(Sparse, , .Status)
			If 'Status Return $$$BuildErr("Error handling object at index {} of type {}:", Status, i, Type)
			If Sparse, Value = "" Continue
			Do Data.%Set(Key, Value)
			
		}
	}
	
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="ValueOut">
<Description>
Converts, if necessary, a Caché property value to the JSON equivalent.
Also returns the JSON datatype (string, number, boolean, or null).</Description>
<ClassMethod>1</ClassMethod>
<FormalSpec>Value:%String,Datatype:%String,*JSONType:%String</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	Set JSONType = "string"
	If Value = "" Quit ""
	If Value = $Char(0) Quit ""
	
	;ISO date, time, timestamp
	If Datatype = "%Date" Quit $ZDate(Value, 3)
	If Datatype = "%Time" Quit $ZTime(Value, 1)
	If Datatype = "%TimeStamp" Quit $Replace(Value, " ", "T")_"Z"
	
	;Booleans output to json as true/false, not 1/0
	If Datatype = "%Boolean" Set JSONType = "boolean" Quit Value
	
	;Numeric values: no quotes needed
	If "%Float, %Numeric, %Decimal, %Integer" [ Datatype {
		Set JSONType = "number"
		Quit Value
	}
	
	Quit Value
]]></Implementation>
</Method>
</Class>
</Export>
