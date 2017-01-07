import backgammon.shared {
	PlayerRepositoryOutputMessage,
	PlayerRepositoryInputMessage,
	formatPlayerRepositoryMessage,
	parsePlayerRepositoryInputMessage,
	parsePlayerRepositoryOutputMessage
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

final class PlayerRepositoryEventBus(Vertx vertx) {
	
	value eventBus = JsonEventBus(vertx);

	shared void sendInboundMessage<OutputMessage>(PlayerRepositoryInputMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies PlayerRepositoryOutputMessage {
		value formattedMessage = formatPlayerRepositoryMessage(message); 
		eventBus.sendMessage(formattedMessage, "PlayerRepositoryMessage", parsePlayerRepositoryOutputMessage, responseHandler);
	}
	
	shared void queueInputMessage(PlayerRepositoryInputMessage message) {
		vertx.runOnContext(() => sendInboundMessage(message, noop));
	}

	shared void registerConsumer(String address, PlayerRepositoryOutputMessage process(PlayerRepositoryInputMessage request)) {
		eventBus.registerConsumer(address, function (Object msg) {
			if (exists request = parsePlayerRepositoryInputMessage(msg)) {
				value response = formatPlayerRepositoryMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
}