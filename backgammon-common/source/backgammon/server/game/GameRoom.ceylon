import backgammon.common {
	OutboundGameMessage,
	MatchId,
	InboundGameMessage,
	StartGameMessage,
	EndGameMessage
}
import backgammon.server.common {
	RoomConfiguration,
	ObtainableLock
}

import ceylon.collection {
	HashMap
}
import ceylon.time {
	Instant
}

shared final class GameRoom(RoomConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value lock = ObtainableLock(); 
	value gameMap = HashMap<MatchId, GameServer>();
	
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
				return server;
			} else {
				return null;
			}
		}
	}
	
	shared Boolean processGameMessage(InboundGameMessage message, Instant currentTime) {
		// TODO implement flooding control
		if (exists server = getGameServer(message)) {
			return server.processGameMessage(message, currentTime);
		} else {
			return false;
		}
	}
	
	shared void removeInactiveGames(Instant currentTime) {
		try (lock) {
			for (entry in gameMap) {
				if (entry.item.isInactive(currentTime)) {
					gameMap.remove(entry.key);
				}
			}
		}
	}
}