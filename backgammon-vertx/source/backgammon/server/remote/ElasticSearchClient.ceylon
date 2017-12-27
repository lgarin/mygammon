import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.core.http {
	HttpClientOptions,
	HttpClient,
	HttpClientResponse
}
import io.vertx.ceylon.core.buffer {
	Buffer
}
import ceylon.json {
	JsonObject,
	Value
}

import ceylon.logging {
	logger
}

final shared class ElasticSearchClient(Vertx vertx, String baseUrl) {
	value idPadding = 1000000000; 
	
	value log = logger(`package`);
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
	
	void put(String url, JsonObject document, void bodyHandler(Buffer? body)) {
		value request = httpClient.putAbs(url);
		request.headers().add("Content-Type", "application/json");
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 201) {
					res.bodyHandler(bodyHandler);
				} else {
					log.warn("PUT to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``");
					bodyHandler(null);
				}
			}
		};
		request.end(document.string);
	}
	
	void get(String url, void bodyHandler(Buffer? body)) {
		value request = httpClient.getAbs(url);
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					res.bodyHandler(bodyHandler);
				} else {
					log.warn("GET to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``");
					bodyHandler(null);
				}
			}
		};
		request.end();
	}
	
	shared void insertDocument(String type, Integer id, JsonObject document, void handleResponse(JsonObject? response)) {
		put("``baseUrl``/``type``/``idPadding+id``/_create", document, (body) {
			if (exists body) {
				handleResponse(body.toJsonObject());
			} else {
				handleResponse(null);
			}
		});
	}
	
	
	void listDocuments(String type, Integer minId, Integer maxCount, void handleResponse({<Integer->JsonObject>*}? response)) {
		get("``baseUrl``/``type``/_search?sort=_id&from=``minId``&size=``maxCount``&filter_path=hits.hits._id,hits.hits._source", (body) {
			if (exists body) {
				function createIdDocumentEntry(Value val) {
					if (is JsonObject val, exists stringId = val.getStringOrNull("_id"), is Integer id = Integer.parse(stringId), exists doc = val.getObjectOrNull("_source")) {
						return [id - idPadding -> doc];
					} else {
						return [];
					}
				}
				
				handleResponse(body.toJsonObject().getObjectOrNull("hits")?.getArrayOrNull("hits")?.flatMap(createIdDocumentEntry));
			} else {
				handleResponse(null);
			}
		});
	}
	
	shared void processAllDocuments(String type, Integer pageSize, void process(JsonObject document), void completion(Integer? nextId), Integer totalCount = 0, variable Integer maxId = 0) {
		listDocuments(type, totalCount, pageSize, (page) {
			if (exists page) {
				variable value pageCount = 0;
				for (id -> document in page) {
					maxId = id;
					pageCount++;
					process(document);
				}
				if (pageCount >= pageSize) {
					processAllDocuments(type, pageSize, process, completion, totalCount + pageCount, maxId);
				} else {
					completion(maxId + 1);
				}
			} else {
				completion(null);
			}
		});
	}
}