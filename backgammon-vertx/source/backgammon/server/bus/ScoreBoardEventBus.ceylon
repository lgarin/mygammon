import io.vertx.ceylon.core {

	Vertx
}
import backgammon.server {

	ServerConfiguration
}
import backgammon.server.store {

	JsonEventStore
}
import backgammon.shared {

	applicationMessages,
	InboundScoreBoardMessage,
	OutboundScoreBoardMessage,
	ScoreBoardMessage
}
import ceylon.json {

	JsonObject
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
					eventBus.sendMessage(formattedMessage, "PlayerRosterMessage", applicationMessages.parse<OutputMessage>, responseHandler);
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
	
	shared void registerConsumer(OutboundScoreBoardMessage process(InboundScoreBoardMessage request)) {
		eventBus.registerConsumer("ScoreBoardMessage", function (JsonObject msg) {
			if (exists request = applicationMessages.parse<InboundScoreBoardMessage>(msg)) {
				return applicationMessages.format(process(request));
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void storeScoreBoardMessage(ScoreBoardMessage message) {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message);
		eventStore.storeEvent("score-board", formattedMessage, (result) {
			if (is Throwable result) {
				throw Exception("Failed to store message ``formattedMessage``");
			}
		});
	}
}