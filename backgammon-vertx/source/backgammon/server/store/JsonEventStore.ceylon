import ceylon.json {

	JsonObject
}
import io.vertx.ceylon.core {

	Vertx
}

import backgammon.server.remote {

	ElasticSearchClient,
	ElasticSearchCriteria,
	ElasticSortOrder,
	elasticSearchCriteriaBuilder
}
import io.vertx.ceylon.core.shareddata {

	Counter
}

final shared class EventSearchCriteria {
	
	ElasticSearchCriteria criteria;
	
	shared new term(String searchField, String searchValue) {
		criteria = elasticSearchCriteriaBuilder.term(searchField, searchValue);
	}
	
	shared new or(EventSearchCriteria left, EventSearchCriteria right) {
		criteria = elasticSearchCriteriaBuilder.or(left.criteria, right.criteria);
	}
	
	shared new and(EventSearchCriteria left, EventSearchCriteria right) {
		criteria = elasticSearchCriteriaBuilder.and(left.criteria, right.criteria);
	}

	shared EventSearchQuery descendingOrder(String orderField) => EventSearchQuery(this, orderField, false);
	
	shared EventSearchQuery ascendingOrder(String orderField) => EventSearchQuery(this, orderField, false);
	
	shared ElasticSearchCriteria toElasticSearchCriteria() => criteria;
}

final shared class EventSearchQuery(EventSearchCriteria criteria, String orderField, Boolean ascending = true) {
	shared ElasticSortOrder toElasticSortOrder() => ascending then elasticSearchCriteriaBuilder.asc(orderField) else elasticSearchCriteriaBuilder.desc(orderField);
	shared ElasticSearchCriteria toElasticSearchCriteria() => criteria.toElasticSearchCriteria();
}

shared final class JsonEventStore(Vertx vertx, String elasticIndexUrl, Integer replayPageSize) {
	
	value eventIndexClient = ElasticSearchClient(vertx, elasticIndexUrl);

	final class ReplayResult(shared Integer eventCount, shared Integer nextId) {
	}
	
	void processAllDocuments(String type, void process(JsonObject document), void completion(ReplayResult|Throwable result), Integer totalCount = 0, variable Integer maxId = 0) {
		
		function processPage({<Integer->JsonObject>*} page) {
			variable value eventCount = 0;
			for (id -> document in page) {
				if (id <= maxId) {
					throw Exception("Id ``id`` was not delivered in ascending order for index ``type`` (Last processed id was ``maxId``)");
				}
				maxId = id;
				eventCount++;
				process(document);
			}
			return eventCount;
		}
		
		eventIndexClient.listDocuments(type, totalCount, replayPageSize, (result) {
			if (is Throwable result) {
				completion(result);
			} else {
				try {
					value processCount = processPage(result);
					if (processCount >= replayPageSize) {
						processAllDocuments(type, process, completion, totalCount + processCount, maxId);
					} else {
						completion(ReplayResult(totalCount + processCount, maxId + 1));
					}
				} catch (Exception e) {
					completion(e);
				}
			}
		});
	}
	
	shared void replayAllEvents<OutboundMessage>(String type, Anything parseOutboundMessage(JsonObject json), void process(OutboundMessage message), void completion(Integer|Throwable result)) {
		void parseAndProcess(JsonObject json) {
			if (is OutboundMessage message = parseOutboundMessage(json)) {
				process(message);
			} else {
				value typeName = `OutboundMessage`.string;
				throw Exception("Cannot parse ``typeName`` from:``json``");
			}
		}
		
		void initializeCounter(Counter counter, ReplayResult replayResult) {
			counter.compareAndSet(0, replayResult.nextId, (result) {
				if (is Throwable result) {
					completion(result);
				} else if (result) {
					completion(replayResult.eventCount);
				} else {
					completion(Exception("Could not set counter ``type`` to ``replayResult.nextId``"));
				}
			});
		}
		
		void fetchCounter(ReplayResult replayResult) {
			vertx.sharedData().getCounter(type, (result) {
				if (is Counter result) {
					initializeCounter(result, replayResult);
				} else {
					completion(result);
				}
			});
		}
		
		void storeNextId(ReplayResult|Throwable result) {
			if (is Throwable result) {
				completion(result);
			} else {
				fetchCounter(result);
			}
		}
		
		void completeNewIndex(Throwable? error) {
			if (is Throwable error) {
				completion(error);
			} else {
				completion(0);
			}
		}
		
		eventIndexClient.checkIndexExistence(type, (result) {
			if (is Throwable result) {
				completion(result);
			} else if (result) {
				processAllDocuments(type, parseAndProcess, storeNextId);
			} else {
				eventIndexClient.createIndex(type, completeNewIndex);
			}
		});
	}
	
	shared void storeEvent(String type, JsonObject event, void handler(Throwable? error)) {
		
		void incrementCounter(Counter counter) {
			counter.incrementAndGet((result) {
				if (is Throwable result) {
					handler(result);
				} else {
					eventIndexClient.insertDocument(type, result, event, handler);
				}
			});
		}
		
		vertx.sharedData().getCounter(type, (result) {
			if (is Counter result) {
				incrementCounter(result);
			} else {
				handler(result);
			}
		});
	}

	shared void queryEvents(String type, EventSearchQuery query, void handleResponse({<JsonObject>*}|Throwable result)) {
		
		void mapResponse({<Integer->JsonObject>*}|Throwable result) {
			if (is Throwable result) {
				handleResponse(result);
			} else {
				handleResponse(result.map(Entry.item));
			}
		}
		eventIndexClient.queryDocuments(type, query.toElasticSearchCriteria(), query.toElasticSortOrder(), 0, replayPageSize, mapResponse);
	}
}