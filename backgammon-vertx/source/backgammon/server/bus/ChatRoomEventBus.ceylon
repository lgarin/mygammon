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
	InboundChatRoomMessage,
	OutboundChatRoomMessage,
	ChatPostedMessage
}
import ceylon.json {

	JsonObject
}

shared final class ChatRoomEventBus(Vertx vertx, ServerConfiguration configuration) {
	
	shared variable Boolean disableOutput = false;
	
	value eventBus = JsonEventBus(vertx);
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize);
	
	shared void sendInboundMessage<OutputMessage>(InboundChatRoomMessage message, void responseHandler(Throwable|OutputMessage response)) given OutputMessage satisfies OutboundChatRoomMessage {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message);
		if (message.mutation) {
			eventStore.storeEvent("chat-``message.roomId``", formattedMessage, (result) {
				if (is Throwable result) {
					responseHandler(result);
				} else {
					eventBus.sendMessage(formattedMessage, "InboundChatMessage-``message.roomId``", applicationMessages.parse<OutputMessage>, responseHandler);
				}
			});
		} else {
			eventBus.sendMessage(formattedMessage, "InboundChatMessage-``message.roomId``", applicationMessages.parse<OutputMessage>, responseHandler);
		}
	}
	
	shared void registerAsyncConsumer(String roomId, Anything(InboundChatRoomMessage, Anything(OutboundChatRoomMessage|Throwable)) processAsync) {
		void parseRequest(JsonObject msg, Anything(JsonObject|Throwable) completion) {
			if (exists request = applicationMessages.parse<InboundChatRoomMessage>(msg)) {
				void formatResponse(OutboundChatRoomMessage|Throwable result) {
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
		
		eventBus.registerAsyncConsumer("InboundChatMessage-``roomId``", parseRequest);
	}
	
	shared void replayAllEvents(String roomId, void process(InboundChatRoomMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("chat-``roomId``", applicationMessages.parse<InboundChatRoomMessage>, process, completion);
	}
	
	shared void publishOutboundMessage(ChatPostedMessage message) {
		if (disableOutput) {
			return;
		}
		value formattedMessage = applicationMessages.format(message); 
		eventBus.publishMessage(formattedMessage, "OutboundChatMessage-``message.roomId``");
	}
	
	shared {String+} publishedAddresses => {"^OutboundChatMessage-.*$"};

}