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
	GameActionResponseMessage,
	InboundGameMessage,
	GameStateResponseMessage,
	InboundMatchMessage,
	CreateGameMessage,
	NextRollMessage,
	GameEventMessage,
	GameTimeoutMessage
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
import backgammon.server.dice {

	DiceRoller
}

shared final class GameRoom(RoomConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster, Anything(InboundMatchMessage) matchCommander, Anything(GameEventMessage) eventRecorder) {
	
	value roomId = RoomId(configuration.roomId);
	value lock = ObtainableLock("GameRoom ``configuration.roomId``"); 
	value managerMap = HashMap<MatchId, GameManager>();
	value diceRoller = DiceRoller();
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
	
	function getGameManager(InboundGameMessage|GameEventMessage message) {
		try (lock) {
			if (is InboundGameMessage message, exists currentManager = managerMap[message.matchId]) {
				return currentManager;
			} else if (is GameEventMessage message, exists currentManager = managerMap[message.matchId]) {
				return currentManager;
			} else if (is CreateGameMessage message) {
				value manager = GameManager(message, configuration, messageBroadcaster, matchCommander);
				managerMap.put(message.matchId, manager);
				_totalGameCount++;
				return manager;
			} else {
				return null;
			}
		}
	}
	
	function getAllGameManagers() {
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
			value result = game.processGameMessage(message);
			if (game.needNewRoll()) {
				eventRecorder(NextRollMessage(game.matchId, diceRoller.roll(), message.timestamp));
			}
			// TODO should we really wait here?
			game.waitForNewRoll();
			return result;
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(message.matchId, message.playerId, black, false);
		}
	}
	
	shared void processEventMessage(GameEventMessage message) {
		if (exists game = getGameManager(message)) {
			switch (message) 
			case (is NextRollMessage) {
				game.setNextRoll(message.roll);
			}
			case (is GameTimeoutMessage) {
				game.notifyTimeouts(message.timestamp);
			}
		}
	}
	
	shared void processMessage(InboundGameMessage|GameEventMessage message) {
		switch (message)
		case (is InboundGameMessage) {
			processGameMessage(message);
		}
		case (is GameEventMessage) {
			processEventMessage(message);
		}
	}
	
	shared void periodicCleanup(Instant currentTime) {
		for (game in getAllGameManagers()) {
			if (game.ended) {
				removeGameManager(game);
			} else {
				if (game.hasHardTimeout(currentTime)) {
					eventRecorder(GameTimeoutMessage(game.matchId, currentTime));
				} else {
					game.notifyTimeouts(currentTime);
				}
				
				if (game.needNewRoll()) {
					eventRecorder(NextRollMessage(game.matchId, diceRoller.roll(), currentTime));
				}
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