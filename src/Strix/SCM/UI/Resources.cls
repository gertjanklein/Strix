Class Strix.SCM.UI.Resources Extends %CSP.Page
{

ClassMethod CSS() As %String
{
	&html<<style type="text/css">
html, body {
  margin: 0;
  padding: 0;
  background-color: #f8f8f8;
}
body, input {
  font: normal 14px Arial, sans-serif;
}
pre {
	background-color: white;
	padding: 2px;
}
form { margin: 0; padding: 0; }
h1 {
	height: 42px;
	background-color: white;
  color: #666;
  font-family: Verdana;
  font-size: 1.5em;
  font-weight: bold;
	margin: 0;
	padding: 15px 0 0 60px;
	border-bottom: 3px double #ccc;
	text-align: left;
	overflow: hidden;
}
#Logo {
	position: absolute;
	left: 5px;
	top: 5px;
	border: none;
}
h2 {
  text-align: left;
  color: #688;
  margin: 0.7em 0 0 0;
  padding: 0.1em 0 0.1em 0;
}
a { color: blue; }
table {
  border-collapse: collapse;
}

#Contents {
  padding: 0 1em 2em 1em;
  clear: both;
}

/* ========== Listing tables */
.List {
  border-collapse: collapse;
  border-spacing: 0;
  margin: 0.5em 1em 0 0;
  font-size: 13px;
}
.List th {
  border: 1px solid #ccc;
  font-weight: normal;
  text-align: left;
  vertical-align: top;
  padding: 1px 0.3em;
  border: 1px solid #ccc;
}
.List td {
  border: 1px solid #ccc;
  padding: 1px 0.3em;
  border: 1px solid #ccc;
  vertical-align: top;
}
.HeaderRow th {
  background-color: #a8c0ff;
  padding: 2px 0.3em;
}
.OddRow td {
  background-color: #ffffff;
}
.EvenRow td {
  background-color: #f6f6ff;
}
.WarningRow td {
  background-color: #ffc0ff;
}
.LoadRow td {
  background-color: #e0ffe0;
}
.SepRow td {
  background-color: #ffe;
  font-size: 1px;
  line-height: 1px;
  height: 8px;
  padding: 0;
  border: none;
}

/* ========== Data entry tables */

.DataEntry {
  border-collapse: collapse;
  margin-top: 0.5em;
  background-color: white;
}
.DataEntry th, .DataEntry td {
  border: 1px solid #ddd;
  padding: 3px 5px;
  vertical-align: baseline;
}
.DataEntry td textarea {
  vertical-align: baseline;
}
.DataEntry th {
  font-weight: normal;
  text-align: left;
  white-space: pre;
}
.DataEntry td {
}
.DataEntry th[colspan] {
  background-color: #ccc;
  font-size: 120%;
}

/* ========== */

.Buttons {
	margin: 1em 0;
	padding: 5px;
	/*border: 1px solid #ddd;*/
	text-align: center;
}

/* ========== */
.Right {
  text-align: right;
}
.NoWrap {
	white-space: nowrap;
}

/* ========== */
.Explain {
	margin: 0.5em 0 0.2em 0;
	color: #664;
	font-size: 100%;
	max-width: 50em;
}
ul.Explain {
	margin: 0;
	padding: 0 0 0 0.5em;
}
ul.Explain li {
	list-style-position: inside;
}
span.Origin {
  font-size: 85%;
  font-style: italic;
	color: #006;
}
div.Summary {
	margin: 1em 0;
	padding: 3px 0.5em;
	background-color: #ffe;
	border: 3px double #eee;
}
.Message {
  margin: 1em 0;
  padding: 5px 5px 5px 25px;
  border: 3px double green;
  background: #ffe url("Strix.SCM.UI.Resources.cls?img=ok") no-repeat scroll 3px 5px;
  color: black;
  font-weight: normal;
}
.ErrorMsg {
  margin: 1em 0;
  padding: 5px;
  border: 3px double red;
  background-color: #ffe;
  color: red;
  font-weight: bold;
}
.sysid {
	color: blue;
}

#LoadExisting {
  margin: 0.5em 0 2em 0;
  border: none;
}
</style>
	>
	
	Quit ""
}

ClassMethod OnPreHTTP() As %Boolean
{
	Set Data = ..ImageData(%request.Get("img"), .ContentType)
	If Data '= "" {
		Set %response.ContentType = ContentType
		Set %response.ContentLength = $Length(Data)
	} Else {
		Set %response.Status = "404 Not found"
	}
	
	Quit 1
}

ClassMethod OnPage() As %Status
{
	Set Data = ..ImageData(%request.Get("img"))
	If Data = "" Set Data = "Not found."
	Write Data
	Quit $$$OK
}

/// Image data; part of class for easier deployment.
ClassMethod ImageData(Name As %String, Output ContentType As %String) As %String
{
	Set Data = ""
	
	If Name = "ok" {
		Set ContentType = "image/gif"
		Set Data = Data_"R0lGODlhEAAQANUAAAAAAP////D78Pr++tLz0ZHeja/orLDprbXrsrzsusvxydf01tbz1eH34OT3"
		Set Data = Data_"4+b45XrOc37SeIHWe4HVe4/eipTgj7ztudDyztXz02C6VmK7WGnBYG/FZnDFZ3nOcXvQc3nNcfH6"
		Set Data = Data_"8EitO06wQlSzSFa0S1m2TWjAXW3EY/39/f///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
		Set Data = Data_"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAACoALAAAAAAQABAAAAZyQJVw"
		Set Data = Data_"SCwaFZSIpLIwCh8okXQKEhQdpqlWpLEON9spSfQZWsJSQ0eKEUamp6khtRZVhHFpKD5P5SFCYFIp"
		Set Data = Data_"IQkpKRNTZSoQUwyHiFoFQghij4laF0IDGWIeWxxEGCNoIiUORQSdWxsNTgMHIBsbHxZOt0ZBADs="
		
	} ElseIf Name = "start" {
		Set ContentType = "image/png"
		;http://www.iconsdb.com/orange-icons/filing-cabinet-icon.html (edited)
		Set Data = Data_"iVBORw0KGgoAAAANSUhEUgAAACoAAAAwCAMAAABQUBiUAAABp1BMVEX/pQD/////pAD+pQD/1Yf/"
		Set Data = Data_"pgT+pAD/3J3/vEL/rRgAACL/uzwAef7/6cEAGKL/6L/+pgQAhP7/68QAAAAAf/7//v0Aff4AQ/7/"
		Set Data = Data_"1IcAART+pQQAgP4ASv7/zG4Ah/4Adv7//vr/+/X/vED/uTr/rxz/7s//sCH+rxz+rRgAwf4ArP7/"
		Set Data = Data_"qQsAxv4Atv7/3Jr+vEIABiX/pgIAWP7/0Hr+0Hr/vUQAHyUAEiX/qxAAsv4AYt3/7Mj/57r/v0oA"
		Set Data = Data_"CTf/qAj//PcAKc7/5LL/3qAAHpL/2JAAbYEAGTUAu/4ANf4AQoEAzv4Aov4AT/4APf7/9uQAtt4A"
		Set Data = Data_"c94AXc7/36UAgZIAQpIAFIL/04H+y20AAFQAKzUAABwAERUACRUAAAkAjP4AJd4Awd0AMN0AAKoA"
		Set Data = Data_"NIEAAG7/tSsAkv4Abv4Aav4AMP4AIN4A0t0Axd0AVt0AP93/8tkAuM4As84AqM4Amr0AYr0AHr0A"
		Set Data = Data_"haIAVKIAd5IAS5IAeoEAJIEAHIEAAHX+yGX/xl0AMjUAAC/+tSz/sygAqP4AZ90Abc4Aac4AAMEA"
		Set Data = Data_"C5AAAH/+tS6LmW+DAAAD2klEQVRIx32V+V8SYRDGZ9kWluUQXFjiEGhZMCAkKFQIyCy8SvPoMstM"
		Set Data = Data_"0+77vu+7P7qZd0/5wYdHBD7PZ+b7zgfeAY7LDnz8VygMa5rmNXVQGx52uPCpneU44LKeg24AtFPu"
		Set Data = Data_"PntPZjE6WQBDLof7VZjk4GwHQPjm86mqKopVUYyvy3Fd1apYVZl2BIDOWcgPA6jHsqholIty3Prq"
		Set Data = Data_"qXPn0R/i+DaaZc6LAFoejo1D7WJ04KTHM8IUP1VvZupN/4nDHtJJVDt6MQTjxygq7OMabt4FLvKV"
		Set Data = Data_"c8071yqz4cejALzuBrdPgPIgDJYhtI9TwdTV85m0gl4eA1MNbn/IjO7nfNYEEKCSqVcQwKoqUtXj"
		Set Data = Data_"GD1OADknwGwaAZ6M7o4KFCUAnwPAH1bQDgCVACgq9AF8OPF4+cST5a01q6qPVQ3AYIhPsKou3XL8"
		Set Data = Data_"8OgYes18Ia37uP1YLwCBBFBUXn339gZ6dX31/dSN91Nz2/Huhak59PZaDqu6eYyGGKscrJ++XT90"
		Set Data = Data_"60X81HwxMz+DE7iQqiRjzfBG10esQFUZgPzyzJ2bZ2avPbvyurSQLi2En45OVVLKTMq/eDlHABSt"
		Set Data = Data_"EUBPfpVUIujnV9/oL36NzSUVBb003SOAEEUJYEIHOM0ADmVSRQKIzSQXKuG73QkCcA9glAA8CDB7"
		Set Data = Data_"88wCAXyPpUsxAmimlMo8AowQAI9Rnk0AATJJNAKE/RH0z7G5sF9BL02zCcAAPvQJ/Hl47wF6K/53"
		Set Data = Data_"835r8/qPLWl7Y3Hp7uLS7y85AqCom01Akrqfp9GHJUtr3cvT6C9STgfAMAMAKYhTpANt4JPuIo01"
		Set Data = Data_"KEEfALikoDLDDoRPhnGsmAQLAEDAKE/ZJB0Ij0T/6E9JUpJVNaIJ+mbxgAz3W9S3VWxthiPp4nVM"
		Set Data = Data_"urAGi7owyrOqgMKsn/oeQmaMxqg7fQlZlHcCuF0uzOoA6VQr4mfdHQABG8BNdQkgQt0jrLsTIMAA"
		Set Data = Data_"Ro4cOcokBUthv95dxs+YRwyAQI2i2QOm5GCqyLrLBw5M6J4wARIE0Bu6dGloiFkOxkqx00F5yFKP"
		Set Data = Data_"RelXoE/AlhxEyQhvmrHWKGpPwLCMAod8ZlXBOQFyWSsUCmU8u2mfUXVQoKoqWNLaeVRbswFYNBEw"
		Set Data = Data_"LiLRBuhxTL0+AIGiBCDaACuPJldWJh+t2AAqRUPm9dYAS52v3vFx707HBhDNaJlFbQAy7JJ1aZYJ"
		Set Data = Data_"oGEDkKmvbePWNi74DuwW77QdpbXR9uwhXBs1Wht5DUDNRzl6WO5TXnTTMqIVF9oR+1V1+muIVhwt"
		Set Data = Data_"TgLaYwLW4qR1DDy/xwTIXk+W05f8N1rs3oOWvbulL/n/foS199NHpeUAAAAASUVORK5CYII="
		
	} ElseIf Name = "cm" {
		Set ContentType = "image/gif"
		Set Data = Data_"R0lGODlhCgAKANUCAEKtP0StQf8AAG2/a97w3qbYpd/x3mu/aajZp/b79vT69MnnyK7crXTDcqra"
		Set Data = Data_"qcfmxtLr0VG0T0ivRpbRlF24Wr7jveHy4Pv9+53UnPn8+cjnx4LIgNfu1v///37HfKfZpq/crmG6"
		Set Data = Data_"XgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
		Set Data = Data_"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAIALAAAAAAKAAoAAAZIQIGA"
		Set Data = Data_"UDgMEASh4BEANAGAxRAaaHoYAAPCCZUoOIDPAdCAQhIRgJGiAG0uE+igAMB0MhYoAFmtJEJcBgIL"
		Set Data = Data_"VU8BGkpEAwMOggJBADs="
		
	}
	
	If Data = "" Quit ""
	
	Set Result = $System.Encryption.Base64Decode(Data)
	
	Quit Result
}

}
