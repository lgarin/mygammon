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

final shared class GameRoomEventBus(Vertx vertx) {

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

	void registerRoomMessageConsumer<in InboundMessage, out OutboundMessage>(String address, InboundMessage? parse(Object json), OutboundMessage process(InboundMessage request)) given OutboundMessage satisfies RoomMessage given InboundMessage satisfies RoomMessage {
		eventBus.registerConsumer(address, function (Object msg) {
			if (is InboundMessage request = parse(msg)) {
				value response = formatRoomMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}

	shared void registerInboundRoomMessageConsumer(String roomId, OutboundRoomMessage process(InboundRoomMessage request)) {
		registerRoomMessageConsumer("InboundRoomMessage-``roomId``", parseInboundRoomMessage, process);
	}
	
	shared void registerInboundTableMessageConsumer(String roomId, OutboundTableMessage process(InboundTableMessage request)) {
		registerRoomMessageConsumer("InboundTableMessage-``roomId``", parseInboundTableMessage, process);
	}
	
	shared void registerInboundMatchMessageConsumer(String roomId, OutboundMatchMessage process(InboundMatchMessage request)) {
		registerRoomMessageConsumer("InboundMatchMessage-``roomId``", parseInboundMatchMessage, process);
	}
	
	void registerParallelRoomMessageConsumer<in InboundMessage, out OutboundMessage>(WorkerExecutor executor, String address, InboundMessage? parse(Object json), OutboundMessage process(InboundMessage request)) given OutboundMessage satisfies RoomMessage given InboundMessage satisfies RoomMessage {
		eventBus.registerParallelConsumer(executor, address, function (Object msg) {
			if (is InboundMessage request = parse(msg)) {
				value response = formatRoomMessage(process(request));
				logger(`package`).info(response.string);
				return response;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void registerInboundGameMessageConsumer(String roomId, Integer threadCount, OutboundGameMessage process(InboundGameMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("game-thread-``roomId``", threadCount);
		registerParallelRoomMessageConsumer(executor, "InboundGameMessage-``roomId``", parseInboundGameMessage, process);
	}
		
	shared Router createEventBusRouter() {
		return eventBus.createEventBusRouter("/*", {"^OutboundRoomMessage-.*$", "^OutboundTableMessage-.*$", "^OutboundGameMessage-.*$"});
	}
}