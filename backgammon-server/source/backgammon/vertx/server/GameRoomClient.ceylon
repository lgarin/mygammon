import io.vertx.ceylon.core.eventbus {

	EventBus,
	Message
}
import ceylon.json {

	Object
}
import backgammon.common {

	parseGameMessage,
	InboundGameMessage,
	OutboundGameMessage,
	formatRoomMessage,
	OutboundRoomMessage,
	InboundRoomMessage,
	parseRoomMessage
}
class GameRoomClient(EventBus eventBus) {
	
	shared void sendInboundRoomMessage<OutboundMessage>(InboundRoomMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies OutboundRoomMessage {
		eventBus.send("InboundRoomMessage-``message.roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseRoomMessage(typeName, body.getObject(typeName))) {
					responseHandler(response);
				} else {
					responseHandler(Exception("Invalid response type: ``typeName``"));
				}
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
	
	shared void sendInboundGameMessage<OutboundMessage>(InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies OutboundGameMessage {
		eventBus.send("InboundGameMessage-``message.roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseGameMessage(typeName, body.getObject(typeName))) {
					responseHandler(response);
				} else {
					responseHandler(Exception("Invalid response type: ``typeName``"));
				}
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
}