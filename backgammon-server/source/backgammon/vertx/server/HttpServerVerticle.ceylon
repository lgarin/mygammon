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

final class HttpServerVerticle() extends Verticle() {
	
	void startHttp(RoomConfiguration roomConfig) {
		
		value authRouterFactory = GoogleAuthRouterFactory(vertx, roomConfig.hostname, roomConfig.port);
		value router = routerFactory.router(vertx);

		router.mountSubRouter("/", authRouterFactory.createUserSessionRouter(roomConfig.playerInactiveTimeout.milliseconds));
		//router.route().handler(loggerHandler.create().handle);		
		
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.mountSubRouter("/eventbus", GameRoomEventBus(vertx).createEventBusRouter());
		
		router.mountSubRouter("/", authRouterFactory.createGoogleLoginRouter());
		router.mountSubRouter("/", GameRoomRouterFactory(vertx, roomConfig.roomId).createRouter());
		router.mountSubRouter("/api", GameRoomRestApi(vertx).createRouter());
		
		vertx.createHttpServer().requestHandler(router.accept).listen(roomConfig.port);
		
		logger(`package`).info("Started http://``roomConfig.hostname``:``roomConfig.port``");
	}
	
	void startRoom(RoomConfiguration roomConfig) {
		value eventBus = GameRoomEventBus(vertx);

		value matchRoom = MatchRoom(roomConfig, eventBus.publishOutboundTableMessage, eventBus.queueInboundMessage);
		eventBus.registerInboundRoomMessageConsumer(roomConfig.roomId, roomConfig.roomThreadCount, matchRoom.processRoomMessage);
		eventBus.registerInboundTableMessageConsumer(roomConfig.roomId, roomConfig.roomThreadCount, matchRoom.processTableMessage);
		eventBus.registerInboundMatchMessageConsumer(roomConfig.roomId, roomConfig.roomThreadCount, matchRoom.processMatchMessage);
		
		value gameRoom = GameRoom(roomConfig, eventBus.publishOutboundGameMessage);
		eventBus.registerInboundGameMessageConsumer(roomConfig.roomId, roomConfig.gameThreadCount, gameRoom.processGameMessage);
		
		variable String lastStatistic = "";
		
		vertx.setPeriodic(roomConfig.serverAdditionalTimeout.milliseconds / 2, void (Integer val) {
			value currentTime = now();
			matchRoom.removeInactivePlayers(currentTime);
			gameRoom.notifySoftTimeouts(currentTime);
			value statistic = "``matchRoom.statistic`` ``gameRoom.statistic``";
			if (statistic != lastStatistic) {
				lastStatistic = statistic;
				logger(`package`).info(statistic);
			}
		});
		
		logger(`package`).info("Started room ``roomConfig.roomId``");
	}

	shared actual void start() {
		value roomConfig = RoomConfiguration(config);
		startHttp(roomConfig);
		startRoom(roomConfig);
	}
}