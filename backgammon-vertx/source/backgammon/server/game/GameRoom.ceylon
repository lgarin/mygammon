

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
	value managerMap = HashMap<MatchId, GameManager>();
	variable Integer _totalGameCount = 0;
	variable Integer _maxGameCount = 0;
	
	value totalGameCount => _totalGameCount;
	value activeGameCount => managerMap.size;
	value maxGameCount {
		if (_maxGameCount < activeGameCount) {
			_maxGameCount = activeGameCount;
		}
		return _maxGameCount;
	}
	
	function getGameManager(InboundGameMessage message) {
		try (lock) {
			if (exists currentManager = managerMap[message.matchId]) {
				return currentManager;
			} else if (is StartGameMessage message) {
				value manager = GameManager(message, configuration, messageBroadcaster, matchCommander);
				managerMap.put(message.matchId, manager);
				_totalGameCount++;
				return manager;
			} else {
				return null;
			}
		}
	}
	
	function getAllGamerMangers() {
		try (lock) {
			return managerMap.items.clone();
		}
	}
	
	void removeGameManager(GameManager game) {
		try (lock) {
			managerMap.remove(game.matchId);
		}
	}
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (exists game = getGameManager(message)) {
			return game.processGameMessage(message);
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(message.matchId, message.playerId, black, false);
		}
	}
	
	shared void periodicCleanup(Instant currentTime) {
		for (game in getAllGamerMangers()) {
			if (game.ended) {
				removeGameManager(game);
			} else {
				game.notifyTimeouts(currentTime);
			}
		}
	}
	
	shared GameRoomStatistic statistic {
		try (lock) {
			return GameRoomStatistic {
				roomId = roomId;
				activeGameCount = activeGameCount;
				maxGameCount = maxGameCount;
				totalGameCount = totalGameCount; 
			};
		}
	}
}