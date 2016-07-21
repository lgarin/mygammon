import backgammon.common {
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
	parseOutboundGameMessage
}

import ceylon.json {
	Object,
	Value
}
import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	WorkerExecutor,
	Future,
	Vertx
}
import io.vertx.ceylon.core.eventbus {
	Message
}
import io.vertx.ceylon.web {
	Router,
	routerFactory=router
}
import io.vertx.ceylon.web.handler.sockjs {
	PermittedOptions,
	SockJSHandlerOptions,
	sockJSHandler,
	BridgeOptions
}

final class GameRoomEventBus(Vertx vertx) {
	
	shared void sendInboundRoomMessage<OutboundMessage>(InboundRoomMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies OutboundRoomMessage {
		vertx.eventBus().send("InboundRoomMessage-``message.roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseOutboundRoomMessage(typeName, body.getObject(typeName))) {
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
		vertx.eventBus().send("InboundGameMessage-``message.roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseOutboundGameMessage(typeName, body.getObject(typeName))) {
					responseHandler(response);
				} else {
					responseHandler(Exception("Invalid response type: ``typeName``"));
				}
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
	
	shared void sendOutboundTableMessage(OutboundTableMessage|OutboundMatchMessage msg) {
		logger(`package`).info(formatRoomMessage(msg).string);
		vertx.eventBus().send("OutboundTableMessage-``msg.tableId``", formatRoomMessage(msg));
	}
	
	shared void sendOutboundGameMessage(OutboundGameMessage msg) {
		logger(`package`).info(formatRoomMessage(msg).string);
		vertx.eventBus().send("OutboundGameMessage-``msg.matchId``", formatRoomMessage(msg));
	}
	
	void registerParallelConsumer(WorkerExecutor executor, String address, Value process(Object msg)) {
		vertx.eventBus().consumer(address, void (Message<Object> message) {
			if (exists body = message.body()) {
				executor.executeBlocking(
					void (Future<Value> result) {
						result.complete(process(body));
					},
					void (Throwable|Value result) {
						if (is Throwable result) {
							message.fail(500, "Processing error: ``result.message``");
						} else {
							message.reply(result);
						}
					});
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	void registerParallelRoomMessageCosumer<in InboundMessage, out OutboundMessage>(WorkerExecutor executor, String address, InboundMessage? parse(String typeName, Object json), OutboundMessage process(InboundMessage request)) given OutboundMessage satisfies RoomMessage given InboundMessage satisfies RoomMessage {
		registerParallelConsumer(executor, address, function (Object msg) {
			logger(`package`).info(msg.string);
			if (exists typeName = msg.keys.first) {
				if (is InboundMessage request = parse(typeName, msg.getObject(typeName))) {
					return formatRoomMessage(process(request));
				} else {
					throw Exception("Invalid request type: ``typeName``");
				}
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
	}
	
	shared void registerInboundRoomMessageConsumer(String roomId, Integer threadCount, OutboundRoomMessage|OutboundTableMessage process(InboundRoomMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("room-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundRoomMessage-``roomId``", parseInboundRoomMessage, process);
	}
	
	shared void registerInboundGameMessageConsumer(String roomId, Integer threadCount, OutboundGameMessage process(InboundGameMessage request)) {
		value executor = vertx.createSharedWorkerExecutor("game-thread-``roomId``", threadCount);
		registerParallelRoomMessageCosumer(executor, "InboundGameMessage-``roomId``", parseInboundGameMessage, process);
	}
	
	function createSockJsHandler() {
		value sockJsOptions = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = {PermittedOptions { addressRegex = "^OutboundTableMessage-.*"; }, PermittedOptions { addressRegex = "^OutboundGameMessage-.*"; } };
		};
		return sockJSHandler.create(vertx, sockJsOptions).bridge(bridgeOptions);
	}
	
	shared Router createEventBusRouter() {
		value router = routerFactory.router(vertx);
		router.route().handler(createSockJsHandler().handle);
		return router;
	}
}