import backgammon.server {
	ServerConfiguration
}
import backgammon.server.store {
	JsonEventStore
}
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
	parseInboundMatchMessage,
	GameEventMessage,
	parseGameEventMessage,
	formatGameEventMessage
}

import ceylon.json {
	Object
}
import ceylon.time {
	now
}

import io.vertx.ceylon.core {
	WorkerExecutor,
	Vertx
}
import io.vertx.ceylon.web {
	Router
}

final shared class GameRoomEventBus(Vertx vertx, ServerConfiguration configuration) {

	shared variable Boolean disableOutput = false;
	
	value eventBus = JsonEventBus(vertx);
	value eventStore = JsonEventStore(vertx, configuration.elasticIndexUrl, configuration.replayPageSize);

	void rethrowExceptionHandler(Anything result) {
		if (is Throwable result) {
			throw result;
		}
	}

	void sendMessage<OutboundMessage>(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage {
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

	void storeAndSendMessage<OutboundMessage>(String indexName, InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage {
		value formattedMessage = formatRoomMessage(message);
		eventStore.storeEvent(indexName, formattedMessage, (result) {
			if (is Throwable result) {
				responseHandler(result);
			} else {
				sendMessage(message, responseHandler);
			}
		});
	}

	shared void sendInboundMessage<OutboundMessage>(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage {
		if (disableOutput) {
			return;
		}
		if (is InboundGameMessage message) {
			storeAndSendMessage("game-``message.roomId``-``message.matchId.date``", message, responseHandler);
		} else {
			storeAndSendMessage("room-``message.roomId``", message, responseHandler);
		}
	}
	
	shared void queueInboundMessage(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message) {
		if (disableOutput) {
			return;
		}
		vertx.runOnContext(() => sendInboundMessage(message, rethrowExceptionHandler));
	}
	
	shared void publishOutboundMessage(OutboundRoomMessage|OutboundTableMessage|OutboundMatchMessage|OutboundGameMessage message) {
		if (disableOutput) {
			return;
		}
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
				return formatRoomMessage(process(request));
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
				return formatRoomMessage(process(request));
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void registerInboundGameMessageConsumer(String roomId, Integer threadCount, OutboundGameMessage process(InboundGameMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("game-workerthread-``roomId``", threadCount);
		registerParallelRoomMessageConsumer(executor, "InboundGameMessage-``roomId``", parseInboundGameMessage, process);
	}
	
	shared void storeGameEventMessage(GameEventMessage message) {
		if (disableOutput) {
			return;
		}
		value formattedMessage = formatGameEventMessage(message); 
		eventStore.storeEvent("game-``message.roomId``-``message.matchId.date``", formattedMessage, (result) {
			if (is Throwable result) {
				throw Exception("Failed to store message ``formattedMessage``");
			} else {
				eventBus.sendMessage(formattedMessage, "GameEventMessage-``message.roomId``", parseGameEventMessage, rethrowExceptionHandler);
			}
		});
	}
	
	shared void registerGameEventMessageCosumer(String roomId, void process(GameEventMessage message)) {
		eventBus.registerConsumer("GameEventMessage-``roomId``", function (Object msg) {
			if (is GameEventMessage request = parseGameEventMessage(msg)) {
				process(request);
				return msg;
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
		
	shared Router createEventBusRouter() {
		return eventBus.createEventBusRouter("/*", {"^OutboundRoomMessage-.*$", "^OutboundTableMessage-.*$", "^OutboundGameMessage-.*$"});
	}
	
	function parseRoomEvent(Object json) {
		if (exists result = parseInboundRoomMessage(json)) {
			return result;
		} else if (exists result = parseInboundTableMessage(json)) {
			return result;
		} else if (exists result = parseInboundMatchMessage(json)) {
			return result;
		} else {
			return null;
		}
	}
	
	shared void replayAllRoomEvents(String roomId, void process(InboundRoomMessage|InboundTableMessage|InboundMatchMessage message), void completion(Integer|Throwable result)) {
		eventStore.replayAllEvents("room-``roomId``", parseRoomEvent, process, completion);
	}
	
	function parseGameEvent(Object json) {
		if (exists result = parseInboundGameMessage(json)) {
			return result;
		} else if (exists result = parseGameEventMessage(json)) {
			return result;
		} else {
			return null;
		}
	}
	
	shared void replayAllGameEvents(String roomId, void process(InboundGameMessage|GameEventMessage message), void completion(Integer|Throwable result)) {
		void replaySumCompletion(Integer previous)(Integer|Throwable result) {
			if (is Integer result) {
				completion(result + previous);
			} else {
				completion(result);
			}
		}
		
		value today = now().date();
		void replayToday(Integer|Throwable result) {
			if (is Throwable result) {
				completion(result);
			} else {
				eventStore.replayAllEvents("game-``roomId``-``today``", parseGameEvent, process, replaySumCompletion(result));
			}
		}
		
		value yersterday = today.minusDays(1);
		void replayYesterday() {
			eventStore.replayAllEvents("game-``roomId``-``yersterday``", parseGameEvent, process, replayToday);
		}
		
		replayYesterday();
	}
}