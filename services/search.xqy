xquery version "1.0-ml";

import module namespace search = "http://marklogic.com/appservices/search"
    at "/MarkLogic/appservices/search/search.xqy";

declare namespace env="http://dveivr.dha.health.mil/xml/envelope";
declare namespace pat="http://dveivr.dha.health.mil/xml/patient";
declare namespace enc="http://dveivr.dha.health.mil/xml/encounter";

declare variable $options := <options xmlns="http://marklogic.com/appservices/search">
	<constraint name='collection' facet='true'>
		<collection prefix="type/">
			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
		</collection>
	</constraint>
	<constraint name='serviceBranch' facet='true'>
		<range type="xs:string" facet="true" collation="http://marklogic.com/collation/en/S1">
			<element ns="http://dveivr.dha.health.mil/xml/patient" name="serviceBranch"/>
			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
	    </range>
	</constraint>
	<constraint name='serviceStatus' facet='true'>
		<range type="xs:string" facet="true" collation="http://marklogic.com/collation/en/S1">
			<element ns="http://dveivr.dha.health.mil/xml/patient" name="serviceStatus"/>
			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
	    </range>
	</constraint>
	<constraint name='category' facet='true'>
		<range type="xs:string" facet="true" collation="http://marklogic.com/collation/en/S1">
			<element ns="http://dveivr.dha.health.mil/xml/patient" name="categoryShortName"/>
			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
	    </range>
	</constraint>
	<constraint name='code' facet='true'>
		<range type="xs:string" collation="http://marklogic.com/collation/" facet="true">
  			<path-index xmlns:enc="http://dveivr.dha.health.mil/xml/encounter">enc:diagnosis/enc:code</path-index>
  			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
			<facet-option>limit=5</facet-option>
		</range>
	</constraint>
	<additional-query>
  		<cts:collection-query>
  			<cts:uri>final</cts:uri>
  		</cts:collection-query>
  	</additional-query>
</options>;

declare function local:format-match-fragment($fragment) {
	object-node {
		"path": fn:string($fragment/@path),
		"fragment": array-node {
			for $node in $fragment/node() 
			return
				typeswitch($node)
				case text() return fn:string($node)
				default return object-node { "match":  fn:string($node) }
		}
	}
};

declare function local:format-patient($doc) {
	object-node {
		"type": "patient",
		"metadata": object-node {
			"imported": $doc/env:envelope/env:metadata/env:import-date/text(),
			"created": $doc/env:envelope/pat:patient/pat:created/text()
		},
		"id": $doc/env:envelope/pat:patient/pat:patientId/text(),
		"firstName": $doc/env:envelope/pat:patient/pat:firstName/text(),
		"lastName": $doc/env:envelope/pat:patient/pat:lastName/text(),
		"gender": ($doc/env:envelope/pat:patient/pat:gender/text(), "Unknown")[1],
		"birthDate": ($doc/env:envelope/pat:patient/pat:birthDate/text(), "None")[1],
		"serviceStatus": fn:string($doc/env:envelope/pat:patient/pat:serviceStatus),
		"enrollmentDate": ($doc/env:envelope/pat:patient/pat:enrollmentDate/text(), "None")[1]
	}
};

declare function local:format-encounter($doc) {
	object-node {
		"type": "encounter",
		"id": $doc/env:envelope/enc:encounter/enc:encounterId/text(),
		"patientId": ($doc/env:envelope/enc:encounter/enc:patientId/text(), "None")[1],
		"provider": (
			if ($doc/env:envelope/enc:encounter/enc:provider/enc:providerId/text()) 
			then
				object-node {
					"providerId": fn:string($doc/env:envelope/enc:encounter/enc:provider/enc:providerId),
					"firstName": fn:string($doc/env:envelope/enc:encounter/enc:provider/enc:firstName),
					"lastname": fn:string($doc/env:envelope/enc:encounter/enc:provider/enc:lastName)
				}
			else
				null-node{}
			),
		"diagnosisText": fn:string($doc/env:envelope/enc:encounter/enc:diagnosisSummaryCommentText/text()),
		"patient": object-node {
			"firstName": fn:string($doc/env:envelope//pat:patient/pat:firstName),
			"lastName": fn:string($doc/env:envelope//pat:patient/pat:lastName)
		}
	}
};

declare function local:format-unknown($doc) {
	object-node {
		"type": "other"
	}
};

declare function local:result-details($result) {
	let $uri := xs:string($result/@uri)
	let $doc := fn:doc($uri)
	let $collections := xdmp:document-get-collections($uri)

	return
		if ($collections eq "patient") 
		then
			local:format-patient($doc)
		else if($collections eq "encounter")
		then
			local:format-encounter($doc)
		else
			local:format-unknown($doc)
};

declare function local:format-result($result) {
	object-node {
		"index": xs:int($result/@index),
		"uri": xs:string($result/@uri),
		"path": xs:string($result/@path),
		"score": xs:double($result/@score),
		"confidence": xs:double($result/@confidence),
		"fitness": xs:double($result/@fitness),
		"data": local:result-details($result),
		"matches": array-node {
			for $match in $result/search:snippet/search:match
			return 
				local:format-match-fragment($match)
		}
	}
};

declare function local:format-facet($facet) {
	object-node {
		"name": fn:string($facet/@name),
		"type": fn:string($facet/@collection),
		"values": array-node {
			for $facet-value in $facet/search:facet-value
			return
				object-node {
					"name": fn:string($facet-value/@name),
					"count": xs:int($facet-value/@count),
					"text": fn:string($facet/value/text())
				}
		}
	}
};


let $query-text := (xdmp:get-request-field("qtext"), "")[1]
let $start := xs:int((xdmp:get-request-field("start"), "1")[1])
let $results := search:search($query-text, $options, $start)
return
	(
		xdmp:set-response-content-type("application/json"),
		object-node {
			"total": xs:int($results/@total),
			"start": xs:int($results/@start),
			"pageLength": xs:int($results/@page-length),
			"qtext": fn:string($results/search:qtext/text()),
			"results": array-node {
				for $result in $results/search:result
				return
					local:format-result($result)
				},
			"facets": array-node {
				for $facet in $results/search:facet
				return 
					local:format-facet($facet)
			}
		}
	)
