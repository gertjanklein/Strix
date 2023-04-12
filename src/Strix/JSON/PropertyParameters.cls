Class Strix.JSON.PropertyParameters
{

/// The JSON name for this property; defaults to the Caché name
/// with the first letter lowercased.
Parameter JSONNAME;

Parameter JSONIO As STRING [ Constraint = ",IN,OUT,CALC,NONE", Flags = ENUM ];

}
