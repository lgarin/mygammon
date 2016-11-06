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

	void sendInboundGenericMessage<in InboundMessage, OutboundMessage>(InboundMessage message, String address, RoomMessage? parseOutboundMessage(String typeName, Object json), void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage given InboundMessage satisfies RoomMessage {
		logger(`package`).info(formatRoomMessage(message).string);
		vertx.eventBus().send(address, formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseOutboundMessage(typeName, body.getObject(typeName))) {
					responseHandler(response);
				} else {
					responseHandler(Exception("Invalid response type: ``typeName``"));
				}
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
	
	shared void queueInboundMessage(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message) {
		vertx.runOnContext(() => sendInboundMessage(message, void (Anything response) {}));
	}
	
	shared void sendInboundMessage<OutboundMessage>(InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies RoomMessage {
		switch (message)
		case (is InboundRoomMessage) {
			sendInboundGenericMessage(message, "InboundRoomMessage-``message.roomId``", parseOutboundRoomMessage, responseHandler);
		}
		case (is InboundTableMessage) {
			sendInboundGenericMessage(message, "InboundTableMessage-``message.roomId``", parseOutboundTableMessage, responseHandler);
		}
		case (is InboundMatchMessage) {
			sendInboundGenericMessage(message, "InboundMatchMessage-``message.roomId``", parseOutboundMatchMessage, responseHandler);
		}
		case (is InboundGameMessage) {
			sendInboundGenericMessage(message, "InboundGameMessage-``message.roomId``", parseOutboundGameMessage, responseHandler);
		}
	}
	
	void publishOutboundGenericMessage(RoomMessage msg, String address) {
		logger(`package`).info(formatRoomMessage(msg).string);
		vertx.eventBus().publish(address, formatRoomMessage(msg));
	}

	shared void publishOutboundMessage(OutboundRoomMessage|OutboundTableMessage|OutboundMatchMessage|OutboundGameMessage message) {
		switch (message)
		case (is OutboundRoomMessage) {
			publishOutboundGenericMessage(message, "OutboundRoomMessage-``message.roomId``");
		}
		case (is OutboundTableMessage) {
			publishOutboundGenericMessage(message, "OutboundTableMessage-``message.tableId``");
		}
		case (is OutboundMatchMessage) {
			publishOutboundGenericMessage(message, "OutboundTableMessage-``message.tableId``");
		}
		case (is OutboundGameMessage) {
			publishOutboundGenericMessage(message, "OutboundGameMessage-``message.matchId``");
		}
	}
	
	void registerParallelConsumer(WorkerExecutor executor, String address, Object process(Object msg)) {
		vertx.eventBus().consumer(address, void (Message<Object> message) {
			if (exists body = message.body()) {
				executor.executeBlocking(
					void (Future<Object> result) {
						result.complete(process(body));
					},
					void (Throwable|Object|Null result) {
						if (is Throwable result) {
							logger(`package`).error("Failed processing for ``message.body() else message``", result);
							message.fail(500, "Processing error: ``result.message``");
						} else if (is Object result) {
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
	
	function createSockJsHandler() {
		value sockJsOptions = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = {PermittedOptions { addressRegex = "^OutboundRoomMessage-.*"; }, PermittedOptions { addressRegex = "^OutboundTableMessage-.*"; }, PermittedOptions { addressRegex = "^OutboundGameMessage-.*"; } };
		};
		return sockJSHandler.create(vertx, sockJsOptions).bridge(bridgeOptions);
	}
	
	shared Router createEventBusRouter() {
		value router = routerFactory.router(vertx);
		router.route("/*").handler(createSockJsHandler().handle);
		return router;
	}
}