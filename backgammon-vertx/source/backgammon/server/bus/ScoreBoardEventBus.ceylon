import backgammon.server {
	ServerConfiguration
}
import backgammon.server.store {
	JsonEventStore,
	EventSearchCriteria
}
import backgammon.shared {
	applicationMessages,
	InboundScoreBoardMessage,
	OutboundScoreBoardMessage,
	PlayerId,
	GameStatisticMessage
}

import ceylon.json {
	JsonObject
}

import io.vertx.ceylon.core {
	Vertx
}
final shared class ScoreBoardEventBus(Vertx vertx, ServerConfiguration configuration) {
	
	shared variable Boolean disableOutput = false;
	
	value eventBus = JsonEventBus(vertx);
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize);
	
	shared void sendInboundMessage<OutputMessage>(InboundScoreBoardMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies OutboundScoreBoardMessage {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message);
		if (message.mutation) {
			eventStore.storeEvent("score-board", formattedMessage, (result) {
				if (is Throwable result) {
					responseHandler(result);
				} else {
					eventBus.sendMessage(formattedMessage, "ScoreBoardMessage", applicationMessages.parse<OutputMessage>, responseHandler);
				}
			});
		} else {
			eventBus.sendMessage(formattedMessage, "ScoreBoardMessage", applicationMessages.parse<OutputMessage>, responseHandler);
		}
	}
	
	void rethrowExceptionHandler(Anything result) {
		if (is Throwable result) {
			throw result;
		}
	}
	
	shared void queueInboundMessage(InboundScoreBoardMessage message) {
		if (disableOutput) {
			return;
		}
		vertx.runOnContext(() => sendInboundMessage(message, rethrowExceptionHandler));
	}

	shared void registerAsyncConsumer(Anything(InboundScoreBoardMessage, Anything(OutboundScoreBoardMessage|Throwable)) processAsync) {
		void parseRequest(JsonObject msg, Anything(JsonObject|Throwable) completion) {
			if (exists request = applicationMessages.parse<InboundScoreBoardMessage>(msg)) {
				void formatResponse(OutboundScoreBoardMessage|Throwable result) {
					if (is Throwable result) {
						completion(result);
					} else {
						completion(applicationMessages.format(result));
					}
				}
				processAsync(request, formatResponse);
			} else {
				completion(Exception("Invalid request: ``msg``"));
			}
		}
		
		eventBus.registerAsyncConsumer("ScoreBoardMessage", parseRequest);
	}

	shared void queryGameStatisticMessages(PlayerId playerId, void completion({GameStatisticMessage*}|Throwable result)) {
		void mapResult({JsonObject*}|Throwable result) {
			if (is Throwable result) {
				completion(result);
			} else {
				completion(result.map(applicationMessages.parse<GameStatisticMessage>).narrow<GameStatisticMessage>());
			}
		}
		value classTerm = EventSearchCriteria.term("class", `GameStatisticMessage`.declaration.name);
		value blackPlayerTerm = EventSearchCriteria.term("blackPlayer.id", playerId.string);
		value whitePlayerTerm = EventSearchCriteria.term("whitePlayer.id", playerId.string);
		value playerCondition = EventSearchCriteria.or(blackPlayerTerm, whitePlayerTerm);
		value query = EventSearchCriteria.and(classTerm, playerCondition).ascendingOrder("timestamp");
		eventStore.queryEvents("score-board", query, mapResult);
	}
	
	shared void replayAllEvents(void process(InboundScoreBoardMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("score-board", applicationMessages.parse<InboundScoreBoardMessage>, process, completion);
	}
}