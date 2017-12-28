import backgammon.shared {
	formatDiceRollMessage,
	GenerateRollMessage,
	parseGenerateRollMessage,
	NewRollMessage,
	parseNewRollMessage
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
shared final class DiceRollEventBus(Vertx vertx) {

	value eventBus = JsonEventBus(vertx);
	
	shared void sendInboundMessage(GenerateRollMessage message, void responseHandler(Throwable|NewRollMessage response)) {
		value formattedMessage = formatDiceRollMessage(message);
		eventBus.sendMessage(formattedMessage, "GenerateRollMessage", parseNewRollMessage, responseHandler); 
	}

	suppressWarnings("redundantNarrowing")
	shared void registerConsumer(NewRollMessage process(GenerateRollMessage request)) {
		eventBus.registerConsumer("GenerateRollMessage", function (JsonObject msg) {
			if (exists request = parseGenerateRollMessage(msg)) {
				value response = formatDiceRollMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
}