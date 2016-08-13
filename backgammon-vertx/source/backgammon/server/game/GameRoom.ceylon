

import backgammon.shared {
	MatchId,
	RoomId,
	EndGameMessage,
	OutboundGameMessage,
	StartGameMessage,
	GameActionResponseMessage,
	InboundGameMessage,
	GameStateResponseMessage
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
import backgammon.server.util {

	ObtainableLock
}
import backgammon.server.room {

	RoomConfiguration
}

shared final class GameRoom(RoomConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value roomId = RoomId(configuration.roomId);
	value lock = ObtainableLock(); 
	value gameMap = HashMap<MatchId, GameServer>();
	variable Integer gameCount = 0;
	
	function getGameServer(InboundGameMessage message) {
		try (lock) {
			if (exists currentServer = gameMap[message.matchId]) {
				if (is EndGameMessage message) {
					gameMap.remove(message.matchId);
				}
				return currentServer;
			} else if (is StartGameMessage message) {
				value server = GameServer(message.playerId, message.opponentId, message.matchId, configuration, messageBroadcaster);
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
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (exists server = getGameServer(message)) {
			return server.processGameMessage(message);
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(message.matchId, message.playerId, black, false);
		}
	}
	
	shared void notifySoftTimeouts(Instant currentTime) {
		for (game in getAllGamerServers()) {
			game.notifyTimeouts(currentTime);
		}
	}
	
	shared GameRoomStatistic statistic {
		try (lock) {
			return GameRoomStatistic(roomId, gameMap.size, gameCount);
		}
	}
}