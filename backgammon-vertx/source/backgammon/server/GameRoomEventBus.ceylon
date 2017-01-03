import backgammon.shared {
	parseInboundGameMessage,
	InboundGameMessage,
	OutboundGameMessage,
	formatRoomMessage,
	OutboundRoomMessage,
	InboundRoomMessage,
	parseInboundRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	RoomMessage,
	parseOutboundRoomMessage,
	parseOutboundGameMessage,
	InboundMatchMessage,
	parseOutboundMatchMessage,
	InboundTableMessage,
	parseOutboundTableMessage,
	parseInboundTableMessage,
	parseInboundMatchMessage
}

import ceylon.json {
	Object
}
import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	WorkerExecutor,
	Vertx
}
import io.vertx.ceylon.web {
	Router
}

final class GameRoomEventBus(Vertx vertx) {

	value eventBus = JsonEventBus(vertx);

	shared void sendInboundMessage<OutboundMessage>(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage {
		value formattedMessage = formatRoomMessage(message);
		switch (message)
		case (is InboundRoomMessage) {
			eventBus.sendMessage(formattedMessage, "InboundRoomMessage-``message.roomId``", parseOutboundRoomMessage, responseHandler);
		}
		case (is InboundTableMessage) {
			eventBus.sendMessage(formattedMessage, "InboundTableMessage-``message.roomId``", parseOutboundTableMessage, responseHandler);
		}
		case (is InboundMatchMessage) {
			eventBus.sendMessage(formattedMessage, "InboundMatchMessage-``message.roomId``", parseOutboundMatchMessage, responseHandler);
		}
		case (is InboundGameMessage) {
			eventBus.sendMessage(formattedMessage, "InboundGameMessage-``message.roomId``", parseOutboundGameMessage, responseHandler);
		}
	}
	
	shared void queueInboundMessage(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message) {
		vertx.runOnContext(() => sendInboundMessage(message, noop));
	}

	shared void publishOutboundMessage(OutboundRoomMessage|OutboundTableMessage|OutboundMatchMessage|OutboundGameMessage message) {
		value formattedMessage = formatRoomMessage(message); 
		switch (message)
		case (is OutboundRoomMessage) {
			eventBus.publishMessage(formattedMessage, "OutboundRoomMessage-``message.roomId``");
		}
		case (is OutboundTableMessage) {
			eventBus.publishMessage(formattedMessage, "OutboundTableMessage-``message.tableId``");
		}
		case (is OutboundMatchMessage) {
			eventBus.publishMessage(formattedMessage, "OutboundTableMessage-``message.tableId``");
		}
		case (is OutboundGameMessage) {
			eventBus.publishMessage(formattedMessage, "OutboundGameMessage-``message.matchId``");
		}
	}

	void registerParallelRoomMessageCosumer<in InboundMessage, out OutboundMessage>(WorkerExecutor executor, String address, InboundMessage? parse(String typeName, Object json), OutboundMessage process(InboundMessage request)) given OutboundMessage satisfies RoomMessage given InboundMessage satisfies RoomMessage {
		eventBus.registerParallelConsumer(executor, address, function (Object msg) {
			if (exists typeName = msg.keys.first) {
				if (is InboundMessage request = parse(typeName, msg.getObject(typeName))) {
					value response = formatRoomMessage(process(request));
					logger(`package`).info(response.string);
					return response;
				} else {
					throw Exception("Invalid request type: ``typeName``");
				}
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void registerInboundRoomMessageConsumer(String roomId, Integer threadCount, OutboundRoomMessage process(InboundRoomMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("room-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundRoomMessage-``roomId``", parseInboundRoomMessage, process);
	}
	
	shared void registerInboundTableMessageConsumer(String roomId, Integer threadCount, OutboundTableMessage process(InboundTableMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("room-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundTableMessage-``roomId``", parseInboundTableMessage, process);
	}
	
	shared void registerInboundMatchMessageConsumer(String roomId, Integer threadCount, OutboundMatchMessage process(InboundMatchMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("room-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundMatchMessage-``roomId``", parseInboundMatchMessage, process);
	}
	
	shared void registerInboundGameMessageConsumer(String roomId, Integer threadCount, OutboundGameMessage process(InboundGameMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("game-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundGameMessage-``roomId``", parseInboundGameMessage, process);
	}
		
	shared Router createEventBusRouter() {
		return eventBus.createEventBusRouter("/*", {"^OutboundRoomMessage-.*$", "^OutboundTableMessage-.*$", "^OutboundGameMessage-.*$"});
	}
}