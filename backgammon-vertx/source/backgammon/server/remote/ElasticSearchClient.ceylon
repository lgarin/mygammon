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
import java.net {

	URLEncoder
}

shared interface ElasticSearchCriteria {
	shared formal String toQueryString();
}

shared class FieldSearchCriteria(shared String searchField, shared String searchValue) satisfies ElasticSearchCriteria {
	toQueryString() => "``URLEncoder.encode(searchField)``:``URLEncoder.encode(searchValue)``";
}

shared class AndSearchCriteria(ElasticSearchCriteria left, ElasticSearchCriteria right) satisfies ElasticSearchCriteria {
	toQueryString() => "(``left.toQueryString()``%20AND%20``right.toQueryString()``)";
}

shared class OrSearchCriteria(ElasticSearchCriteria left, ElasticSearchCriteria right) satisfies ElasticSearchCriteria {
	toQueryString() => "(``left.toQueryString()``%20OR%20``right.toQueryString()``)";
}

final shared class ElasticSortOrder(shared String orderField, shared Boolean ascending = true) {
	value order => ascending then  "asc" else "desc";
	shared String toOrderString() => "``orderField``:``order``";
}

shared object elasticSearchCriteriaBuilder {
	
	shared ElasticSearchCriteria term(String name, String term) => FieldSearchCriteria(name, term);
	shared ElasticSearchCriteria and(ElasticSearchCriteria left, ElasticSearchCriteria right) => AndSearchCriteria(left, right);
	shared ElasticSearchCriteria or(ElasticSearchCriteria left, ElasticSearchCriteria right) => OrSearchCriteria(left, right);
	
	shared ElasticSortOrder asc(String name) => ElasticSortOrder(name, true);
	shared ElasticSortOrder desc(String name) => ElasticSortOrder(name, false);
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
	
	void put(String url, JsonObject document, void bodyHandler(Buffer|Throwable result)) {
		value request = httpClient.putAbs(url);
		request.exceptionHandler(bodyHandler);
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
	
	void get(String url, void bodyHandler(Buffer|Throwable body)) {
		value request = httpClient.getAbs(url);
		request.exceptionHandler(bodyHandler);
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
	
	shared void insertDocument(String index, Integer id, JsonObject document, void handleResponse(Throwable? result)) {
		put("``baseUrl``/backgammon-``index``/doc/``idPadding+id``/_create", document, (result) {
			if (is Throwable result) {
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
	
	shared void checkIndexExistence(String index, void handleResponse(Boolean|Throwable result)) {
		value url = "``baseUrl``/backgammon-``index``";
		value request = httpClient.headAbs(url);
		request.exceptionHandler(handleResponse);
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					handleResponse(true);
				} else if (res.statusCode() == 404) {
					handleResponse(false);
				} else {
					handleResponse(Exception("HEAD to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``"));
				}
			}
		};
		request.end();
	}
	
	shared void createIndex(String index, void handleResponse(Throwable? error)) {
		value url = "``baseUrl``/backgammon-``index``";
		value request = httpClient.putAbs(url);
		request.exceptionHandler(handleResponse);
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					handleResponse(null);
				} else {
					handleResponse(Exception("PUT to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``"));
				}
			}
		};
		request.end();
	}
	
	shared void listDocuments(String index, Integer offset, Integer maxCount, void handleResponse({<Integer->JsonObject>*}|Throwable result)) {
		value url = "``baseUrl``/backgammon-``index``/doc/_search?sort=_id&from=``offset``&size=``maxCount``&filter_path=hits.hits._id,hits.hits._source";
		get(url, (result) {
			if (is Throwable result) {
				handleResponse(result);
			} else {
				handleResponse(parseHits(result.toJsonObject()));
			}
		});
	}
	
	shared void queryDocuments(String index, ElasticSearchCriteria criteria, ElasticSortOrder order, Integer offset, Integer maxCount, void handleResponse({<Integer->JsonObject>*}|Throwable result)) {
		
		value url = "``baseUrl``/backgammon-``index``/doc/_search?q=``criteria.toQueryString()``&sort=``order.toOrderString()``&track_scores=false&from=``offset``&size=``maxCount``&filter_path=hits.hits._id,hits.hits._source";
		get(url, (result) {
			if (is Throwable result) {
				handleResponse(result);
			} else {
				handleResponse(parseHits(result.toJsonObject()));
			}
		});
	}
}