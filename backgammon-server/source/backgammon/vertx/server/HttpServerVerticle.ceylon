import backgammon.common {
	InboundRoomMessage,
	InboundGameMessage
}
import backgammon.server.common {
	RoomConfiguration
}
import backgammon.server.game {
	GameRoom
}
import backgammon.server.match {
	MatchRoom
}

import ceylon.logging {
	logger
}
import ceylon.time {
	Duration,
	now
}

import io.vertx.ceylon.core {
	Verticle
}
import io.vertx.ceylon.web {
	routerFactory=router
}
import io.vertx.ceylon.web.handler {
	loggerHandler,
	staticHandler
}
import io.vertx.ceylon.web.handler.sockjs {
	SockJSHandlerOptions,
	BridgeOptions,
	PermittedOptions,
	sockJSHandler
}

shared final class HttpServerVerticle() extends Verticle() {
	
	value roomId = "test";
	value hostname = "localhost";
	value port = 8080;
	
	// TODO read config from vertx.getOrCreateContext().config() 
	value config = RoomConfiguration(roomId, 100, Duration(60000), Duration(30000));

	function createSockJsHandler() {
		value sockJsOptions = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = {PermittedOptions { addressRegex = "^OutboundTableMessage-.*"; }, PermittedOptions { addressRegex = "^OutboundGameMessage-.*"; } };
		};
		return sockJSHandler.create(vertx, sockJsOptions).bridge(bridgeOptions);
	}
	
	void startHttp() {
		value router = routerFactory.router(vertx);
		value authRouterFactory = GoogleAuthRouterFactory(vertx, hostname, port);
		router.mountSubRouter("/", authRouterFactory.createUserSessionRouter(config.sessionTimeout.milliseconds));
		router.route().handler(loggerHandler.create().handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.route("/eventbus/*").handler(createSockJsHandler().handle);
		router.mountSubRouter("/", authRouterFactory.createGoogleLoginRouter());
		router.mountSubRouter("/", GameRoomRouterFactory(vertx, roomId).createRouter());
		router.mountSubRouter("/api", GameRoomRestApi(vertx).createRouter());
		vertx.createHttpServer().requestHandler(router.accept).listen(port);
		
		logger(`package`).info("Started http://``hostname``:``port``");
	}
	
	void startRoom() {
		
		value eventBus = GameRoomEventBus(vertx);
		
		value matchRoom = MatchRoom(config, eventBus.sendOutboundTableMessage);
		eventBus.registerInboundRoomMessageConsumer(roomId, config.roomThreadCount, (InboundRoomMessage request) => matchRoom.processRoomMessage(request, now()));
		
		value gameRoom = GameRoom(config, eventBus.sendOutboundGameMessage);
		eventBus.registerInboundGameMessageConsumer(roomId, config.gameThreadCount, (InboundGameMessage request) => gameRoom.processGameMessage(request, now()));
		
		vertx.setPeriodic(config.gameInactiveTimeout.milliseconds, void (Integer val) {
			value currentTime = now();
			matchRoom.removeInactivePlayers(currentTime);
			gameRoom.removeInactiveGames(currentTime);
		});
		
		logger(`package`).info("Started room ``roomId``");
	}

	shared actual void start() {
		startHttp();
		startRoom();
	}
}