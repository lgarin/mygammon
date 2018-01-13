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
	NextRollMessage,
	GameEventMessage,
	GameTimeoutMessage,
	GameMessage,
	StartGameMessage
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

	function getGameManager(GameMessage message) {
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
	
	void orderNewDiceRoll(GameManager game, Instant timestamp) {
		if (game.diceRollQueue.needNewRoll()) {
			eventRecorder(NextRollMessage(game.matchId, diceRoller.roll(), timestamp));
		}
	}
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (exists game = getGameManager(message)) {
			value result = game.processGameMessage(message); 
			orderNewDiceRoll(game, message.timestamp);
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
				game.diceRollQueue.setNextRoll(message.roll);
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
	
	void processTimeout(GameManager game, Instant currentTime) {
		if (game.hasHardTimeout(currentTime)) {
			eventRecorder(GameTimeoutMessage(game.matchId, currentTime));
		} else {
			game.notifyTimeouts(currentTime);
		}
	}
	
	shared void periodicCleanup(Instant currentTime) {
		for (game in getAllGameManagers()) {
			if (game.ended) {
				removeGameManager(game);
			} else {
				processTimeout(game, currentTime);
				orderNewDiceRoll(game, currentTime);
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