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
	Verticle,
	Future
}

final class GameRoomVerticle() extends Verticle() {
	
	variable String lastStatistic = "";
	value log = logger(`package`);
	
	void handleStatistic(MatchRoom matchRoom, GameRoom gameRoom) {
		value statistic = "``matchRoom.statistic`` ``gameRoom.statistic``";
		if (statistic != lastStatistic) {
			lastStatistic = statistic;
			log.info(statistic);
		}
	}
	

	shared actual void startAsync(Future<Anything> startFuture) {
		value roomConfig = ServerConfiguration(config);
		value rosterEventBus = PlayerRosterEventBus(vertx, roomConfig);
		value roomEventBus = GameRoomEventBus(vertx, roomConfig);
		
		value matchRoom = MatchRoom(roomConfig, roomEventBus.publishOutboundMessage, roomEventBus.queueInboundMessage, rosterEventBus.queueInputMessage);
		value gameRoom = GameRoom(roomConfig, roomEventBus.publishOutboundMessage, roomEventBus.queueInboundMessage, roomEventBus.storeGameEventMessage);
		
		void finishStartup() {
			roomEventBus.registerInboundRoomMessageConsumer(roomConfig.roomId, matchRoom.processRoomMessage);
			roomEventBus.registerInboundTableMessageConsumer(roomConfig.roomId, matchRoom.processTableMessage);
			roomEventBus.registerInboundMatchMessageConsumer(roomConfig.roomId, matchRoom.processMatchMessage);
			
			roomEventBus.registerInboundGameMessageConsumer(roomConfig.roomId, roomConfig.gameThreadCount, gameRoom.processGameMessage);
			roomEventBus.registerGameEventMessageCosumer(roomConfig.roomId, gameRoom.processEventMessage);
			
			matchRoom.resetPeriodicNotification(now());
			
			vertx.setPeriodic(roomConfig.serverAdditionalTimeout.milliseconds / 2, void (Integer val) {
				value currentTime = now();
				matchRoom.periodicCleanup(currentTime);
				gameRoom.periodicCleanup(currentTime);
				matchRoom.periodicNotification(currentTime);
				handleStatistic(matchRoom, gameRoom);
			});
			
			roomEventBus.disableOutput = false;
			rosterEventBus.disableOutput = false;
			log.info("Started room : ``roomConfig.roomId``");
			startFuture.complete();
		}
		
		void replayGameRoom() {
			roomEventBus.replayAllGameEvents(roomConfig.roomId, gameRoom.processMessage, (result) {
				if (is Throwable result) {
					startFuture.fail(result);
				} else {
					log.info("Replayed ``result`` events in game room ``roomConfig.roomId``");
					finishStartup();
				}
			});
		}
		
		void replayMatchRoom() {
			roomEventBus.replayAllRoomEvents(roomConfig.roomId, matchRoom.processMessage, (result) {
				if (is Throwable result) {
					startFuture.fail(result);
				} else {
					log.info("Replayed ``result`` events in match room ``roomConfig.roomId``");
					replayGameRoom();
				}
			});
		}
		
		log.info("Starting room ``roomConfig.roomId``...");
		roomEventBus.disableOutput = true;
		rosterEventBus.disableOutput = true;
		replayMatchRoom();
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		log.info("Stopped room : ``roomConfig.roomId``");
	}
}