import ceylon.json {
	JsonObject,
	Value
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.core.buffer {
	Buffer
}
import io.vertx.ceylon.core.http {
	HttpClientOptions,
	HttpClient,
	HttpClientResponse
}

final shared class ElasticSearchClient(Vertx vertx, String baseUrl) {
	value idPadding = 1000000000; 
	
	variable HttpClient? _httpClient = null;
	
	function createHttpClient() {
		value options = HttpClientOptions {
			ssl = false;
			trustAll =  true;
		};
		return vertx.createHttpClient(options);
	}
	
	value httpClient {
		return _httpClient else (_httpClient = createHttpClient());
	}
	
	void put(String url, JsonObject document, void bodyHandler(Buffer|Exception result)) {
		value request = httpClient.putAbs(url);
		request.headers().add("Content-Type", "application/json");
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 201) {
					res.bodyHandler(bodyHandler);
				} else {
					bodyHandler(Exception("PUT to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``"));
				}
			}
		};
		request.end(document.string);
	}
	
	void get(String url, void bodyHandler(Buffer|Exception body)) {
		value request = httpClient.getAbs(url);
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					res.bodyHandler(bodyHandler);
				} else {
					bodyHandler(Exception("GET to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``"));
				}
			}
		};
		request.end();
	}
	
	shared void insertDocument(String index, Integer id, JsonObject document, void handleResponse(Exception? result)) {
		put("``baseUrl``/``index``/doc/``idPadding+id``/_create", document, (result) {
			if (is Exception result) {
				handleResponse(result);
			} else {
				handleResponse(null);
			}
		});
	}
	
	function parseHits(JsonObject response) {
		function createIdDocumentEntry(Value val) {
			if (is JsonObject val, exists stringId = val.getStringOrNull("_id"), is Integer id = Integer.parse(stringId), exists doc = val.getObjectOrNull("_source")) {
				return [id - idPadding -> doc];
			} else {
				return [];
			}
		}
		
		return response.getObjectOrNull("hits")?.getArrayOrNull("hits")?.flatMap(createIdDocumentEntry) else {};
	}
	
	shared void listDocuments(String index, Integer offset, Integer maxCount, void handleResponse({<Integer->JsonObject>*}|Exception result)) {
		value url = "``baseUrl``/``index``/doc/_search?sort=_id&from=``offset``&size=``maxCount``&filter_path=hits.hits._id,hits.hits._source";
		get(url, (result) {
			if (is Exception result) {
				handleResponse(result);
			} else {
				handleResponse(parseHits(result.toJsonObject()));
			}
		});
	}
}