Include Ensemble

/// REST superclass
Class Strix.Ens.Rest.REST Extends %CSP.REST [ Abstract ]
{

/// Default content type for responses
Parameter CONTENTTYPE = "application/json";

/// Default content text encoding type for responses
Parameter CHARSET = "UTF-8";

/// Whether to handle request for cross-origin resource sharing.
/// Disabled by default.
Parameter HandleCorsRequest = 0;

/// If ExposeServerExceptions is true, details of internal
/// errors will be returned.
Parameter ExposeServerExceptions = 0;

/// The name of the Ensemble Business Service class to create. If not
/// specified, the name of the class the projection is used in will
/// be suffixed with ".Service".
Parameter ServiceClassName;

/// The name of the Business Service as used in the Ensemble
/// production. Required for proper operation.
Parameter ServiceName;

/// Comma-separated list of REST methods to create entry points for
/// in the generated service class. The default is *, meaning all.
Parameter Methods = "*";

// =====

/// Create an Ensemble Business Service class for this REST service
Projection ServiceProjection As Strix.Ens.Rest.RESTServiceProjection;

// =====

/// Default error handler.
ClassMethod HandleError(Method As %String = "", Status As %Status = "", Desc As %String = "") As %Status
{
  #dim %response As %CSP.Response
  
  ; Alsways log information about the error
  Set Msg = "Error occurred"_$Select(Method '= "": " in method "_Method_": ", 1: ": ")
  If Desc '= "" Set Msg = Msg_Desc_": "
  If Status '= "", 'Status Set Msg = Msg_$System.Status.GetErrorText(Status)
  $$$LOGERROR(Msg)
  
  ; If we should return error information, let IRIS handle it by
  ; returning an error status.
  If ..#ExposeServerExceptions {
    If Desc '= "" Set Status = $System.Status.AppendStatus($$$ERROR($$$GeneralError, Desc), Status)
    Quit Status
  }
  
  ; Not exposing error info; just set status to Internal server error.
  Set %response.Status = 500
  Set %response.ContentType = "", %response.CharSet = ""
  
  Quit $$$OK
}

// =====

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!--<Route Url="/method" Method="GET" Call="Method"/>-->
</Routes>
}

}
