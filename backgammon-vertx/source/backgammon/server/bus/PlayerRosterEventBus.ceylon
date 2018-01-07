import backgammon.server {
	ServerConfiguration
}
import backgammon.server.store {
	JsonEventStore
}
import backgammon.shared {
	PlayerRosterOutboundMessage,
	PlayerRosterInboundMessage,
	applicationMessages
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
	
	shared void sendInboundMessage<OutputMessage>(PlayerRosterInboundMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies PlayerRosterOutboundMessage {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message); 
		eventStore.storeEvent("player-roster", formattedMessage, (result) {
			if (is Throwable result) {
				responseHandler(result);
			} else {
				eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", applicationMessages.parse<OutputMessage>, responseHandler);
			}
		});
	}

	void rethrowExceptionHandler(Anything result) {
		if (is Throwable result) {
			throw result;
		}
	}

	shared void queueInputMessage(PlayerRosterInboundMessage message) {
		if (disableOutput) {
			return;
		}
		vertx.runOnContext(() => sendInboundMessage(message, rethrowExceptionHandler));
	}

	shared void registerConsumer(PlayerRosterOutboundMessage process(PlayerRosterInboundMessage request)) {
		eventBus.registerConsumer("PlayerRosterMessage", function (JsonObject msg) {
			if (exists request = applicationMessages.parse<PlayerRosterInboundMessage>(msg)) {
				return applicationMessages.format(process(request));
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void replayAllEvents(void process(PlayerRosterInboundMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("player-roster", applicationMessages.parse<PlayerRosterInboundMessage>, process, completion);
	}
}