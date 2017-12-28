import backgammon.shared {
	PlayerRosterOutboundMessage,
	PlayerRosterInboundMessage,
	parsePlayerRosterOutboundMessage,
	formatPlayerRosterMessage,
	parsePlayerRosterInboundMessage
}

import ceylon.json {
	JsonObject
}
import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Vertx
}
import backgammon.server.store {

	JsonEventStore
}
import backgammon.server {

	ServerConfiguration
}

final shared class PlayerRosterEventBus(Vertx vertx, ServerConfiguration configuration) {
	
	value eventBus = JsonEventBus(vertx);
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize);
	
	shared void sendInboundMessage<OutputMessage>(PlayerRosterInboundMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies PlayerRosterOutboundMessage {
		value formattedMessage = formatPlayerRosterMessage(message); 
		eventStore.storeEvent("playerroster", formattedMessage, (result) {
			if (is Throwable result) {
				responseHandler(result);
			} else {
				eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", parsePlayerRosterOutboundMessage, responseHandler);
			}
		});
	}

	shared void queueInputMessage(PlayerRosterInboundMessage message) {
		vertx.runOnContext(() => sendInboundMessage(message, noop));
	}

	shared void registerConsumer(PlayerRosterOutboundMessage process(PlayerRosterInboundMessage request)) {
		eventBus.registerConsumer("PlayerRosterMessage", function (JsonObject msg) {
			if (exists request = parsePlayerRosterInboundMessage(msg)) {
				value response = formatPlayerRosterMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void replayAllEvents(void process(PlayerRosterInboundMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("playerroster", parsePlayerRosterInboundMessage, process, completion);
	}
}