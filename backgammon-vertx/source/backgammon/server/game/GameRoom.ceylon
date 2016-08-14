

import backgammon.server.room {
	RoomConfiguration
}
import backgammon.server.util {
	ObtainableLock
}
import backgammon.shared {
	MatchId,
	RoomId,
	OutboundGameMessage,
	StartGameMessage,
	GameActionResponseMessage,
	InboundGameMessage,
	GameStateResponseMessage,
	InboundMatchMessage
}
import backgammon.shared.game {
	black
}

import ceylon.collection {
	HashMap
}
import ceylon.time {
	Instant
}

shared final class GameRoom(RoomConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster, Anything(InboundMatchMessage) matchCommander) {
	
	value roomId = RoomId(configuration.roomId);
	value lock = ObtainableLock(); 
	value gameMap = HashMap<MatchId, GameServer>();
	variable Integer gameCount = 0;
	
	function getGameServer(InboundGameMessage message) {
		try (lock) {
			if (exists currentServer = gameMap[message.matchId]) {
				return currentServer;
			} else if (is StartGameMessage message) {
				value server = GameServer(message, configuration, messageBroadcaster, matchCommander);
				gameMap.put(message.matchId, server);
				gameCount++;
				return server;
			} else {
				return null;
			}
		}
	}
	
	function getAllGamerServers() {
		try (lock) {
			return gameMap.items.clone();
		}
	}
	
	void removeGameServer(GameServer game) {
		try (lock) {
			gameMap.remove(game.matchId);
		}
	}
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (exists server = getGameServer(message)) {
			return server.processGameMessage(message);
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(message.matchId, message.playerId, black, false);
		}
	}
	
	shared void periodicCleanup(Instant currentTime) {
		for (game in getAllGamerServers()) {
			if (game.ended) {
				removeGameServer(game);
			} else {
				game.notifyTimeouts(currentTime);
			}
		}
	}
	
	shared GameRoomStatistic statistic {
		try (lock) {
			return GameRoomStatistic(roomId, gameMap.size, gameCount);
		}
	}
}