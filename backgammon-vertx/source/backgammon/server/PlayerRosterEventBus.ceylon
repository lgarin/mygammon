import backgammon.shared {
	PlayerRosterOutboundMessage,
	PlayerRosterInboundMessage,
	parsePlayerRosterOutboundMessage,
	formatPlayerRosterMessage,
	parsePlayerRosterInboundMessage
}

import ceylon.json {
	Object
}
import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Vertx
}

final class PlayerRosterEventBus(Vertx vertx) {
	
	value eventBus = JsonEventBus(vertx);

	shared void sendInboundMessage<OutputMessage>(PlayerRosterInboundMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies PlayerRosterOutboundMessage {
		value formattedMessage = formatPlayerRosterMessage(message); 
		eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", parsePlayerRosterOutboundMessage, responseHandler);
	}
	
	shared void queueInputMessage(PlayerRosterInboundMessage message) {
		// TODO use a persistent queue
		vertx.runOnContext(() => sendInboundMessage(message, noop));
	}

	shared void registerConsumer(PlayerRosterOutboundMessage process(PlayerRosterInboundMessage request)) {
		eventBus.registerConsumer("PlayerRosterMessage", function (Object msg) {
			if (exists request = parsePlayerRosterInboundMessage(msg)) {
				value response = formatPlayerRosterMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
}