xquery version "1.0-ml";

declare namespace env="http://dveivr.dha.health.mil/xml/envelope";
declare namespace pat="http://dveivr.dha.health.mil/xml/patient";
declare namespace enc="http://dveivr.dha.health.mil/xml/encounter";

declare function local:format-patient($data, $encounters) {
	object-node {
		"id": fn:string($data/pat:patientId),
		"patient": object-node {
			"firstName": fn:string($data/pat:firstName),
			"lastName": fn:string($data/pat:lastName),
			"serviceStatus": fn:string($data/pat:serviceStatus),
			"category": fn:string($data/pat:category),
			"categoryName": fn:string($data/pat:categoryName),
			"age": math:floor(fn:days-from-duration(fn:current-dateTime() - xs:dateTime($data/pat:birthDate)) div 365),
			"encounters": array-node {
				for $enc in $encounters
				order by xs:dateTime(fn:string($enc/enc:visitDate))
				return
					object-node {
						"visitDate": fn:string($enc/enc:visitDate)
					}
			}
		}
	}
};

declare function local:format-encounter($data, $patient) {
	object-node {
		"id": fn:string($data/enc:encounterId),
		"encounter": object-node {
			"visitDate": fn:string($data/enc:visitData),
			"diagnosisSummary": fn:string($data/enc:diagnosisSummaryCommentText),
			"procedureSummary": fn:string($data/enc:procedureSummaryCommentText),
			"diagnosis": (
					if (fn:count($data//enc:diagnosis) gt 0) 
					then
						array-node {
							for $diagnosis in $data//enc:diagnosis
							return object-node {
								"code": fn:string($diagnosis/enc:code),
								"name": fn:string($diagnosis/enc:name)
							}
						}
					else
						null-node{}
				)
		}, 
		"patient": object-node {
			"id": fn:string($patient/pat:patientId),
			"firstName": fn:string($patient/pat:firstName),
			"lastName": fn:string($patient/pat:lastName)
		}
	}
};

let $uri := xdmp:get-request-field("uri")
let $doc := fn:doc($uri)
let $collections := xdmp:document-get-collections($uri)

let $_ := xdmp:set-response-content-type("application/json")
return
	if ($collections eq "patient")
	then
		local:format-patient($doc//pat:patient, $doc//enc:encounter)
	else if ($collections eq "encounter")
	then
		local:format-encounter($doc//enc:encounter, $doc//pat:patient)
	else
		xdmp:set-response-code(404, "Document not found")



