import backgammon.common {
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
	staticHandler
}

shared final class HttpServerVerticle() extends Verticle() {
	
	value roomId = "test";
	value hostname = "localhost";
	value port = 8080;
	
	// TODO read config from vertx.getOrCreateContext().config() 
	value config = RoomConfiguration(roomId, 100, Duration(60000));

	void startHttp() {
		value authRouterFactory = GoogleAuthRouterFactory(vertx, hostname, port);
		value router = routerFactory.router(vertx);

		router.mountSubRouter("/", authRouterFactory.createUserSessionRouter(config.playerInactiveTimeout.milliseconds));
		//router.route().handler(loggerHandler.create().handle);
		
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.mountSubRouter("/eventbus", GameRoomEventBus(vertx).createEventBusRouter());
		
		router.mountSubRouter("/", authRouterFactory.createGoogleLoginRouter());
		router.mountSubRouter("/", GameRoomRouterFactory(vertx, roomId).createRouter());
		router.mountSubRouter("/api", GameRoomRestApi(vertx).createRouter());
		
		vertx.createHttpServer().requestHandler(router.accept).listen(port);
		
		logger(`package`).info("Started http://``hostname``:``port``");
	}
	
	void startRoom() {
		value eventBus = GameRoomEventBus(vertx);
		
		void sendGameCommand(InboundGameMessage message) {
			// do not send the message immedialty
			// TODO hack in order to avoid inital roll message coming to the client before the created game message
			vertx.setTimer(config.serverAdditionalTimeout.milliseconds, void (Integer timerId) {
				eventBus.sendInboundMessage(message, void (Anything response) {});
			});
		}
		
		value matchRoom = MatchRoom(config, eventBus.publishOutboundTableMessage, sendGameCommand);
		eventBus.registerInboundRoomMessageConsumer(roomId, config.roomThreadCount, matchRoom.processRoomMessage);
		eventBus.registerInboundTableMessageConsumer(roomId, config.roomThreadCount, matchRoom.processTableMessage);
		eventBus.registerInboundMatchMessageConsumer(roomId, config.roomThreadCount, matchRoom.processMatchMessage);
		
		value gameRoom = GameRoom(config, eventBus.publishOutboundGameMessage);
		eventBus.registerInboundGameMessageConsumer(roomId, config.gameThreadCount, gameRoom.processGameMessage);
		
		vertx.setPeriodic(config.playerInactiveTimeout.milliseconds, void (Integer val) {
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