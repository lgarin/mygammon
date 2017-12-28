import backgammon.server.bus {
	GameRoomEventBus,
	PlayerRosterEventBus
}
import backgammon.server.game {
	GameRoom
}
import backgammon.server.match {
	MatchRoom
}
import backgammon.server.room {
	RoomConfiguration
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

class GameRoomVerticle() extends Verticle() {
	
	variable String lastStatistic = "";
	value log = logger(`package`);
	
	void handleStatistic(MatchRoom matchRoom, GameRoom gameRoom) {
		value statistic = "``matchRoom.statistic`` ``gameRoom.statistic``";
		if (statistic != lastStatistic) {
			lastStatistic = statistic;
			log.info(statistic);
		}
	}

	shared actual void start() {
		value roomConfig = ServerConfiguration(config);
		value repoEventBus = PlayerRosterEventBus(vertx, roomConfig);
		value roomEventBus = GameRoomEventBus(vertx);
		
		value matchRoom = MatchRoom(roomConfig, roomEventBus.publishOutboundMessage, roomEventBus.queueInboundMessage, repoEventBus.queueInputMessage);
		roomEventBus.registerInboundRoomMessageConsumer(roomConfig.roomId, matchRoom.processRoomMessage);
		roomEventBus.registerInboundTableMessageConsumer(roomConfig.roomId, matchRoom.processTableMessage);
		roomEventBus.registerInboundMatchMessageConsumer(roomConfig.roomId, matchRoom.processMatchMessage);
		
		value gameRoom = GameRoom(roomConfig, roomEventBus.publishOutboundMessage, roomEventBus.queueInboundMessage);
		roomEventBus.registerInboundGameMessageConsumer(roomConfig.roomId, roomConfig.gameThreadCount, gameRoom.processGameMessage);
		
		vertx.setPeriodic(roomConfig.serverAdditionalTimeout.milliseconds / 2, void (Integer val) {
			value currentTime = now();
			matchRoom.periodicCleanup(currentTime);
			gameRoom.periodicCleanup(currentTime);
			matchRoom.periodicNotification(currentTime);
			handleStatistic(matchRoom, gameRoom);
		});
		
		log.info("Started room : ``roomConfig.roomId``");
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		log.info("Stopped room : ``roomConfig.roomId``");
	}
}