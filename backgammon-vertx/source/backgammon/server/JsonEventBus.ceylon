import ceylon.json {
	Object
}
import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Vertx,
	Future,
	WorkerExecutor
}
import io.vertx.ceylon.core.eventbus {
	Message
}
import io.vertx.ceylon.web {
	routerFactory=router,
	Router
}
import io.vertx.ceylon.web.handler.sockjs {
	BridgeOptions,
	sockJSHandler,
	PermittedOptions,
	SockJSHandlerOptions
}

final class JsonEventBus(Vertx vertx) {
	
	shared void sendMessage<OutboundMessage>(Object message, String address, Anything parseOutboundMessage(Object json), void responseHandler(Throwable|OutboundMessage response)) {
		logger(`package`).info(message.string);
		vertx.eventBus().send(address, message, void (Throwable|Message<Object?> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), is OutboundMessage response = parseOutboundMessage(body)) {
				responseHandler(response);
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
	
	shared void registerParallelConsumer(WorkerExecutor executor, String address, Object process(Object msg)) {
		vertx.eventBus().consumer(address, void (Message<Object?> message) {
			if (exists body = message.body()) {
				executor.executeBlocking(
					void (Future<Object?> result) {
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
	
	shared void registerConsumer(String address, Object process(Object msg)) {
		vertx.eventBus().consumer(address, void (Message<Object?> message) {
			if (exists body = message.body()) {
				try { 
					value result = process(body);
					message.reply(result);
				} catch (Exception exception) {
					logger(`package`).error("Failed processing for ``message.body() else message``", exception);
					message.fail(500, "Processing error: ``exception.message``");
				}
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	shared void publishMessage(Object message, String address) {
		logger(`package`).info(message.string);
		vertx.eventBus().publish(address, message);
	}
		
	function createSockJsHandler({String*} addressRegexIterable) {
		value sockJsOptions = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = addressRegexIterable.map((regex) =>  PermittedOptions { addressRegex = regex; });
		};
		return sockJSHandler.create(vertx, sockJsOptions).bridge(bridgeOptions);
	}
	
	shared Router createEventBusRouter(String path, {String*} addressRegexIterable) {
		value router = routerFactory.router(vertx);
		router.route(path).handler(createSockJsHandler(addressRegexIterable).handle);
		return router;
	}
}