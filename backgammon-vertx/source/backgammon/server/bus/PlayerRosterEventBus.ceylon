import backgammon.server {
	ServerConfiguration
}
import backgammon.server.store {
	JsonEventStore,
	EventSearchCriteria
}
import backgammon.shared {
	OutboundPlayerRosterMessage,
	InboundPlayerRosterMessage,
	applicationMessages,
	PlayerId
}

import ceylon.json {
	JsonObject
}

import io.vertx.ceylon.core {
	Vertx
}

final shared class PlayerRosterEventBus(Vertx vertx, ServerConfiguration configuration) {
	
	shared variable Boolean disableOutput = false;
	
	value eventBus = JsonEventBus(vertx);
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize, configuration.replayPageTimeout);
	
	shared void sendInboundMessage<OutputMessage>(InboundPlayerRosterMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies OutboundPlayerRosterMessage {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message);
		if (message.mutation) {
			eventStore.storeEvent("player-roster", formattedMessage, (result) {
				if (is Throwable result) {
					responseHandler(result);
				} else {
					eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", applicationMessages.parse<OutputMessage>, responseHandler);
				}
			});
		} else {
			eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", applicationMessages.parse<OutputMessage>, responseHandler);
		}
	}

	void rethrowExceptionHandler(Anything result) {
		if (is Throwable result) {
			throw result;
		}
	}

	shared void queueInboundMessage(InboundPlayerRosterMessage message) {
		if (disableOutput) {
			return;
		}
		vertx.runOnContext(() => sendInboundMessage(message, rethrowExceptionHandler));
	}

	shared void registerAsyncConsumer(Anything(InboundPlayerRosterMessage, Anything(OutboundPlayerRosterMessage|Throwable)) processAsync) {
		void parseRequest(JsonObject msg, Anything(JsonObject|Throwable) completion) {
			if (exists request = applicationMessages.parse<InboundPlayerRosterMessage>(msg)) {
				void formatResponse(OutboundPlayerRosterMessage|Throwable result) {
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
		
		eventBus.registerAsyncConsumer("PlayerRosterMessage", parseRequest);
	}
	
	shared void replayAllEvents(void process(InboundPlayerRosterMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("player-roster", applicationMessages.parse<InboundPlayerRosterMessage>, process, completion);
	}
	
	shared void queryInboundPlayerMessages(PlayerId playerId, void completion({InboundPlayerRosterMessage*}|Throwable result)) {
		void mapResult({JsonObject*}|Throwable result) {
			if (is Throwable result) {
				completion(result);
			} else {
				completion(result.map(applicationMessages.parse<InboundPlayerRosterMessage>).narrow<InboundPlayerRosterMessage>().sort(byIncreasing(InboundPlayerRosterMessage.timestamp)));
			}
		}
		value criteria = EventSearchCriteria.term("playerInfo.id", playerId.string);
		eventStore.queryEvents("player-roster", criteria, mapResult);
	}
}