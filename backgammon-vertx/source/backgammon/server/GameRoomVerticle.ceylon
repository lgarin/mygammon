import backgammon.server.bus {
	GameRoomEventBus,
	PlayerRosterEventBus,
	ScoreBoardEventBus
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
import backgammon.shared {
	InboundGameMessage,
	GameEventMessage,
	MatchId
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
		value scoreEventBus = ScoreBoardEventBus(vertx, roomConfig);
		
		value matchRoom = MatchRoom {
			configuration = roomConfig;
			messageBroadcaster = roomEventBus.publishOutboundMessage;
			gameCommander = roomEventBus.queueInboundMessage;
			playerRepository = rosterEventBus.queueInboundMessage;
		};
		
		value gameRoom = GameRoom {
			configuration = roomConfig;
			messageBroadcaster = roomEventBus.publishOutboundMessage;
			matchCommander = roomEventBus.queueInboundMessage;
			eventRecorder = roomEventBus.storeGameEventMessage;
			statisticRecorder = scoreEventBus.queueInboundMessage;
		};
		
		void finishStartup() {
			roomEventBus.registerInboundRoomMessageConsumer(roomConfig.roomId, matchRoom.processRoomMessage);
			roomEventBus.registerInboundTableMessageConsumer(roomConfig.roomId, matchRoom.processTableMessage);
			roomEventBus.registerInboundMatchMessageConsumer(roomConfig.roomId, matchRoom.processMatchMessage);
			
			roomEventBus.registerInboundGameMessageConsumer(roomConfig.roomId, roomConfig.gameThreadCount, gameRoom.processGameMessage);
			roomEventBus.registerGameEventMessageConsumer(roomConfig.roomId, gameRoom.processEventMessage);
			
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
			scoreEventBus.disableOutput = false;
			startFuture.complete();
		}
		
		void filterAndProcessGameEvents(Set<MatchId> recentMatches)(InboundGameMessage|GameEventMessage message) {
			if (recentMatches.contains(message.matchId)) {
				gameRoom.processMessage(message);
			}
		}
		
		void replayGameRoom() {
			roomEventBus.replayAllGameEvents(roomConfig.roomId, filterAndProcessGameEvents(matchRoom.listRecentMatches()), (result) {
				if (is Throwable result) {
					startFuture.fail(result);
				} else {
					log.info("Game room ``roomConfig.roomId`` events : ``result``");
					finishStartup();
				}
			});
		}
		
		void replayMatchRoom() {
			// TODO replay only active games
			roomEventBus.replayAllRoomEvents(roomConfig.roomId, matchRoom.processMessage, (result) {
				if (is Throwable result) {
					startFuture.fail(result);
				} else {
					log.info("Match room ``roomConfig.roomId`` events : ``result``");
					replayGameRoom();
				}
			});
		}
		
		log.info("Starting room ``roomConfig.roomId``...");
		roomEventBus.disableOutput = true;
		rosterEventBus.disableOutput = true;
		scoreEventBus.disableOutput = true;
		replayMatchRoom();
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		log.info("Stopped room : ``roomConfig.roomId``");
	}
}