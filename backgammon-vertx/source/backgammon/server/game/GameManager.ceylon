
import backgammon.server.dice {
	DiceRollQueue
}
import backgammon.server.util {
	ObtainableLock
}
import backgammon.shared {
	MatchId,
	PlayerId,
	UndoneMovesMessage,
	UndoMovesMessage,
	StartTurnMessage,
	GameActionResponseMessage,
	PlayerReadyMessage,
	InitialRollMessage,
	GameStateRequestMessage,
	TurnTimedOutMessage,
	MakeMoveMessage,
	EndTurnMessage,
	InvalidMoveMessage,
	GameStateResponseMessage,
	EndGameMessage,
	StartGameMessage,
	OutboundGameMessage,
	DesynchronizedMessage,
	PlayedMoveMessage,
	PlayerBeginMessage,
	NotYourTurnMessage,
	InboundGameMessage,
	InboundMatchMessage,
	EndMatchMessage,
	systemPlayerId,
	TakeTurnMessage,
	PingMatchMessage,
	PlayerInfo,
	GameStatisticMessage,
	ControlRollMessage,
	InvalidRollMessage,
	GameJoker,
	takeTurnJoker,
	controlRollJoker,
	undoTurnJoker,
	UndoTurnMessage,
	replayTurnJoker,
	ReplayTurnMessage
}
import backgammon.shared.game {
	GameConfiguration,
	Game,
	black,
	white,
	CheckerColor,
	player1Color,
	player2Color,
	DiceRoll
}

import ceylon.time {
	Instant
}

final class GamePlayerState(shared PlayerId id, shared CheckerColor color) {
	shared variable PlayerInfo? info = null;
	shared variable Integer invalidMoves = 0;
	shared variable Integer successiveTimeouts = 0;
}

final class GameManager(StartGameMessage startGameMessage, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster, Anything(InboundMatchMessage) matchCommander, Anything(GameStatisticMessage) statisticRecorder) {
	
	shared MatchId matchId = startGameMessage.matchId;
	
	value player1 = GamePlayerState(startGameMessage.player1Id, player1Color);
	value player2 = GamePlayerState(startGameMessage.player2Id, player2Color);
	
	value lock = ObtainableLock("GameManager ``matchId``"); 
	
	shared DiceRollQueue diceRollQueue = DiceRollQueue(matchId.string);
	
	variable Boolean softTimeoutNotified = false;
	
	value game = Game(startGameMessage.timestamp.plus(configuration.playerInactiveTimeout));
	
	function toPlayerColor(PlayerId playerId) {
		if (playerId == player1.id) {
			return player1.color;
		} else if (playerId == player2.id) {
			return player2.color;
		} else {
			return null;
		}
	}
	
	function toPlayer(CheckerColor color) {
		return switch (color)
		case (black) player1
		case (white) player2;
	}
	
	function toPlayerId(CheckerColor color) => toPlayer(color).id;
	
	function sendInitialRoll(Instant timestamp) {
		value roll = diceRollQueue.takeNextRoll();
		if (game.initialRoll(roll, timestamp, configuration.maxRollDuration)) {
			messageBroadcaster(InitialRollMessage(matchId, player1.id, player1.color, roll.getValue(player1.color), roll, configuration.maxRollDuration));
			messageBroadcaster(InitialRollMessage(matchId, player2.id, player2.color, roll.getValue(player2.color), roll, configuration.maxRollDuration));
			return true;
		} else {
			return false;
		}
	}
	
	void resetSuccessiveTimeoutCount(CheckerColor color) {
		toPlayer(color).successiveTimeouts = 0;
	}
	
	void increaseSuccessiveTimeoutCount(CheckerColor color) {
		toPlayer(color).successiveTimeouts++;
	}
	
	void increaseInvalidMoveCount(CheckerColor color) {
		toPlayer(color).invalidMoves++;
	}
	
	function endGame(PlayerId playerId, Instant timestamp, PlayerId winnerId = systemPlayerId) {
		if (game.end(timestamp, toPlayerColor(winnerId))) {
			matchCommander(EndMatchMessage(playerId, matchId, winnerId, game.score));
			if (exists blackPlayer = toPlayer(black).info, exists whitePlayer = toPlayer(white).info) {
				statisticRecorder(GameStatisticMessage(matchId, blackPlayer, whitePlayer, game.currentStatistic));
			}
			return true;
		} else {
			return false;
		}
	}
	
	function surrenderGame(PlayerId playerId, CheckerColor playerColor, Instant timestamp) {
		if (exists currentColor = game.currentColor) {
			value opponentId = toPlayerId(playerColor.oppositeColor);
			return endGame(playerId, timestamp, opponentId);
		} else {
			return endGame(playerId, timestamp);
		}
	}
	
	function beginNextTurn(Instant timestamp, GameJoker? joker = null, DiceRoll? nextRoll = null) {
		value nextColor = game.currentColor;
		assert (exists nextColor);
		value roll = nextRoll else diceRollQueue.takeNextRoll();
		value factor = roll.isPair then 2 else 1;
		value turnDuration = game.hasAvailableMove(nextColor, roll) then configuration.maxTurnDuration.scale(factor) else configuration.maxEmptyTurnDuration;
		value maxUndo = configuration.maxUndoPerTurn * factor;
		assert (game.beginTurn(nextColor, roll, timestamp, turnDuration, maxUndo));
		messageBroadcaster(StartTurnMessage(matchId, toPlayerId(nextColor), nextColor, roll, turnDuration, maxUndo, joker));
		return true;
	}
	
	function endTurn(CheckerColor playerColor, Instant timestamp) {
		softTimeoutNotified = false;
		
		if (player1.successiveTimeouts + player2.successiveTimeouts >= configuration.maxSkippedGameTurn) {
			return endGame(systemPlayerId, timestamp);
		} else if (player1.successiveTimeouts >= configuration.maxSkippedPlayerTurn) {
			return surrenderGame(player1.id, player1.color, timestamp);
		} else if (player2.successiveTimeouts >= configuration.maxSkippedPlayerTurn) {
			return surrenderGame(player2.id, player2.color, timestamp);
		} else if (player1.invalidMoves > configuration.maxWarningCount) {
			return surrenderGame(player1.id, player1.color, timestamp);
		} else if (player2.invalidMoves > configuration.maxWarningCount) {
			return surrenderGame(player2.id, player2.color, timestamp);
		} else if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.endTurn(playerColor, timestamp)) {
			return beginNextTurn(timestamp);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), timestamp, toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function undoMoves(CheckerColor playerColor, Instant timestamp) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.undoMoves(playerColor)) {
			messageBroadcaster(UndoneMovesMessage(matchId, toPlayerId(playerColor), playerColor));
			return true;
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function makeMove(CheckerColor playerColor, Integer sourcePosition, Integer targetPosition) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.moveChecker(playerColor, sourcePosition, targetPosition)) {
			messageBroadcaster(PlayedMoveMessage(matchId, toPlayerId(playerColor), playerColor, sourcePosition, targetPosition));
			return true;
		} else {
			increaseInvalidMoveCount(playerColor);
			messageBroadcaster(InvalidMoveMessage(matchId, toPlayerId(playerColor), playerColor, sourcePosition, targetPosition));
			return false;
		}
	}
	
	function beginFirstTurn(CheckerColor currentColor, Instant timestamp) {
		value roll = diceRollQueue.takeNextRoll();
		value factor = roll.isPair then 2 else 1;
		value turnDuration = configuration.maxTurnDuration.scale(factor);
		value maxUndo = configuration.maxUndoPerTurn * factor;
		if (game.beginTurn(currentColor, roll, timestamp, turnDuration, maxUndo)) {
			messageBroadcaster(StartTurnMessage(matchId, toPlayerId(currentColor), currentColor, roll, turnDuration, maxUndo));
			return true;
		} else {
			return false;
		}
	}
	
	function beginGame(CheckerColor playerColor, Instant timestamp) {
		if (game.begin(playerColor, timestamp)) {
			messageBroadcaster(PlayerReadyMessage(matchId, toPlayerId(playerColor), playerColor));
			if (exists currentColor = game.currentColor) {
				return beginFirstTurn(currentColor, timestamp);
			} else if (exists roll = game.currentRoll, roll.isPair) {
				return sendInitialRoll(timestamp);
			} else {
				// first player annouced ready
				return true;
			}
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function takeTurn(CheckerColor playerColor, Instant timestamp) {
		
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.takeTurn(playerColor, timestamp)) {
			return beginNextTurn(timestamp, takeTurnJoker);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), timestamp, toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function controlRoll(CheckerColor playerColor, DiceRoll nextRoll, Instant timestamp) {
		
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (!nextRoll.valid) {
			increaseInvalidMoveCount(playerColor);
			messageBroadcaster(InvalidRollMessage(matchId, toPlayerId(playerColor), playerColor, nextRoll));
			return false;
		} else if (game.controlRoll(playerColor, timestamp)) {
			return beginNextTurn(timestamp, controlRollJoker, nextRoll);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), timestamp, toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function undoTurn(CheckerColor playerColor, Instant timestamp) {
		
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.undoTurn(playerColor, timestamp)) {
			return beginNextTurn(timestamp, undoTurnJoker);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), timestamp, toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function replayTurn(CheckerColor playerColor, Instant timestamp) {
		
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.replayTurn(playerColor, timestamp)) {
			return beginNextTurn(timestamp, replayTurnJoker);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), timestamp, toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function definePlayerInfo(PlayerId playerId, PlayerInfo playerInfo) {
		if (playerId == player1.id) {
			player1.info = playerInfo;
		} else if (playerId == player2.id) {
			player2.info = playerInfo;
		}
		return player1.info exists && player2.info exists;
	}
	
	function handleMessage(InboundGameMessage message, CheckerColor playerColor) {
		resetSuccessiveTimeoutCount(playerColor);
		
		switch (message) 
		case (is StartGameMessage) {
			if (definePlayerInfo(message.playerId, message.playerInfo)) {
				return GameActionResponseMessage(matchId, message.playerId, playerColor, sendInitialRoll(message.timestamp));
			} else {
				return GameActionResponseMessage(matchId, message.playerId, playerColor, false);
			}
		}
		case (is PlayerBeginMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, beginGame(playerColor, message.timestamp));
		}
		case (is MakeMoveMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, makeMove(playerColor, message.sourcePosition, message.targetPosition));
		}
		case (is UndoMovesMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, undoMoves(playerColor, message.timestamp));
		}
		case (is EndTurnMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, endTurn(playerColor, message.timestamp));
		}
		case (is EndGameMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, surrenderGame(toPlayerId(playerColor), playerColor, message.timestamp));
		}
		case (is TakeTurnMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, takeTurn(playerColor, message.timestamp));
		}
		case (is ControlRollMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, controlRoll(playerColor, message.roll, message.timestamp));
		}
		case (is UndoTurnMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, undoTurn(playerColor, message.timestamp));
		}
		case (is ReplayTurnMessage) {
			matchCommander(PingMatchMessage(message.playerId, matchId));
			return GameActionResponseMessage(matchId, message.playerId, playerColor, replayTurn(playerColor, message.timestamp));
		}
		case (is GameStateRequestMessage) {
			return GameStateResponseMessage(matchId, message.playerId, playerColor, game.buildState(message.timestamp));
		}
	}
	
	function doSoftTimeout(Instant currentTime) {
		softTimeoutNotified = true;
		
		if (exists currentColor = game.currentColor) {
			messageBroadcaster(TurnTimedOutMessage(matchId, toPlayerId(currentColor), currentColor));
		} else {
			if (game.mustRollDice(player1.color)) {
				messageBroadcaster(TurnTimedOutMessage(matchId, player1.id, player1.color));
			}
			if (game.mustRollDice(player2.color)) {
				messageBroadcaster(TurnTimedOutMessage(matchId, player2.id, player2.color));
			}
		}
		return false;
	}
	
	void doHardTimeout(Instant timestamp) {
		if (exists currentColor = game.currentColor) {
			increaseSuccessiveTimeoutCount(currentColor);
			endTurn(currentColor, timestamp);
		} else {
			endGame(systemPlayerId, timestamp);
		}
	}
	
	function handleHardTimeout(InboundGameMessage message, CheckerColor playerColor) {
		doHardTimeout(message.timestamp);
		return GameActionResponseMessage(matchId, message.playerId, playerColor, false);
	}
	
	void doTimeoutNotifications(Instant currentTime) {
		if (game.timedOut(currentTime.minus(configuration.serverAdditionalTimeout))) {
			doHardTimeout(currentTime);
		} else if (!softTimeoutNotified && game.timedOut(currentTime)) {
			doSoftTimeout(currentTime);
		}
	}
	
	shared void notifyTimeouts(Instant currentTime) {
		try (lock) {
			doTimeoutNotifications(currentTime);
		}
	}
	
	shared Boolean hasHardTimeout(Instant timestamp) {
		try (lock) {
			return game.timedOut(timestamp.minus(configuration.serverAdditionalTimeout));
		}
	}
	
	function process(InboundGameMessage message, CheckerColor color) {
		if (hasHardTimeout(message.timestamp)) {
			return handleHardTimeout(message, color);
		} else {
			return handleMessage(message, color);
		}
	}

	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (is GameStateRequestMessage message) {
			try (lock) {
				// TODO cannot determine color
				return GameStateResponseMessage(matchId, message.playerId, player1.color, game.buildState(message.timestamp));
			}
		} else if (exists color = toPlayerColor(message.playerId)) {
			try (lock) {
				return process(message, color);
			}
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(matchId, message.playerId, player1.color, false);
		}
	}
	
	shared Boolean ended {
		try (lock) {
		 	return game.ended;
		 }
	}
}