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
	PlayerId,
	PlayerStatisticUpdateMessage
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
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize);
	
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

	shared void queueInputMessage(InboundPlayerRosterMessage message) {
		if (disableOutput) {
			return;
		}
		vertx.runOnContext(() => sendInboundMessage(message, rethrowExceptionHandler));
	}

	shared void registerConsumer(OutboundPlayerRosterMessage process(InboundPlayerRosterMessage request)) {
		eventBus.registerConsumer("PlayerRosterMessage", function (JsonObject msg) {
			if (exists request = applicationMessages.parse<InboundPlayerRosterMessage>(msg)) {
				return applicationMessages.format(process(request));
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void replayAllEvents(void process(InboundPlayerRosterMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("player-roster", applicationMessages.parse<InboundPlayerRosterMessage>, process, completion);
	}
	
	shared void queryPlayerTransactions(PlayerId playerId, void completion({PlayerStatisticUpdateMessage*}|Throwable result)) {
		void mapResult({JsonObject*}|Throwable result) {
			if (is Throwable result) {
				completion(result);
			} else {
				completion(result.map(applicationMessages.parse<InboundPlayerRosterMessage>).narrow<PlayerStatisticUpdateMessage>());
			}
		}
		eventStore.queryEvents("player-roster", EventSearchCriteria("playerInfo.id", playerId.string, "timestamp", false), mapResult);
	}
}