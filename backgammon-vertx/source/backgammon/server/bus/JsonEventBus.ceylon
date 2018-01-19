import ceylon.json {
	JsonObject
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
	
	value log = logger(`package`);
	
	shared void sendMessage<OutboundMessage>(JsonObject message, String address, Anything parseOutboundMessage(JsonObject json), void responseHandler(Throwable|OutboundMessage response)) {
		log.info("Req ``message.string``");
		vertx.eventBus().send(address, message, void (Throwable|Message<JsonObject?> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), is OutboundMessage response = parseOutboundMessage(body)) {
				responseHandler(response);
			} else {
				responseHandler(Exception("Invalid response: ``result.body() else "<no content>"``"));
			}
		});
	}
	
	shared void registerParallelConsumer(WorkerExecutor executor, String address, JsonObject process(JsonObject msg)) {
		vertx.eventBus().consumer(address, void (Message<JsonObject?> message) {
			if (exists body = message.body()) {
				executor.executeBlocking(
					void (Future<JsonObject?> result) {
						result.complete(process(body));
					},
					void (Throwable|JsonObject|Null result) {
						if (is Throwable result) {
							log.error("Failed processing for ``message.body() else message``", result);
							message.fail(500, "Processing error: ``result.message``");
						} else if (is JsonObject result) {
							log.info("Rep ``result.string``");
							message.reply(result);
						}
					});
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	shared void registerConsumer(String address, JsonObject process(JsonObject msg)) {
		vertx.eventBus().consumer(address, void (Message<JsonObject?> message) {
			if (exists body = message.body()) {
				try { 
					value result = process(body);
					log.info("Res ``result.string``");
					message.reply(result);
				} catch (Exception exception) {
					log.error("Failed processing for ``message.body() else message``", exception);
					message.fail(500, "Processing error: ``exception.message``");
				}
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	shared void registerAsyncConsumer(String address, void process(JsonObject msg, Anything(JsonObject|Throwable) callback)) {
		
		vertx.eventBus().consumer(address, void (Message<JsonObject?> message) {
			void reply(JsonObject|Throwable result) {
				if (is Throwable result) {
					log.error("Failed processing for ``message.body() else message``", result);
					message.fail(500, "Processing error: ``result.message``");
				} else {
					log.info("Res ``result.string``");
					message.reply(result);
				}
			}
			
			if (exists body = message.body()) {
				try { 
					process(body, reply);
				} catch (Exception exception) {
					log.error("Failed processing for ``message.body() else message``", exception);
					message.fail(500, "Processing error: ``exception.message``");
				}
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	shared void publishMessage(JsonObject message, String address) {
		log.info("Pub ``message.string``");
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