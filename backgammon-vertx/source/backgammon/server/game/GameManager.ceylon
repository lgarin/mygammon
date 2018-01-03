
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
	TakeTurnMessage
}
import backgammon.shared.game {
	GameConfiguration,
	Game,
	black,
	white,
	CheckerColor,
	player1Color,
	player2Color
}

import ceylon.time {
	Instant
}
import backgammon.server.dice {

	DiceRoller
}

final class GameManager(StartGameMessage startGameMessage, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster, Anything(InboundMatchMessage) matchCommander) {
	
	shared MatchId matchId = startGameMessage.matchId;
	value player1Id = startGameMessage.playerId;
	value player2Id = startGameMessage.opponentId;
	
	value lock = ObtainableLock(); 
	value diceRoller = DiceRoller();
	
	// TODO should be in game state
	variable Integer blackInvalidMoves = 0;
	variable Integer whiteInvalidMoves = 0;
	variable Integer blackSuccessiveTimeouts = 0;
	variable Integer whiteSuccessiveTimeouts = 0;
	
	variable Boolean softTimeoutNotified = false;
	
	value game = Game();
	
	function toPlayerColor(PlayerId playerId) {
		if (playerId == player1Id) {
			return player1Color;
		} else if (playerId == player2Id) {
			return player2Color;
		} else {
			return null;
		}
	}
	
	function toPlayerId(CheckerColor color) {
		switch (color)
		case (black) {
			return player1Id;
		}
		case (white) {
			return player2Id;
		}
	}
	
	function sendInitialRoll(Instant timestamp) {
		value roll = diceRoller.roll();
		if (game.initialRoll(roll, timestamp, configuration.maxRollDuration)) {
			messageBroadcaster(InitialRollMessage(matchId, player1Id, player1Color, roll.getValue(player1Color), roll, configuration.maxRollDuration));
			messageBroadcaster(InitialRollMessage(matchId, player2Id, player2Color, roll.getValue(player2Color), roll, configuration.maxRollDuration));
			return true;
		} else {
			return false;
		}
	}
	
	void increaseInvalidMoveCount(CheckerColor playerColor) {
		switch (playerColor)
		case (black) {
			blackInvalidMoves++;
		}
		case (white) {
			whiteInvalidMoves++;
		}
	}
	
	void increasePlayerTimeoutCount(CheckerColor color) {
		switch (color)
		case (black) { 
			blackSuccessiveTimeouts++;
		}
		case (white) { 
			whiteSuccessiveTimeouts++;
		}
	}
	
	void resetPlayerTimeoutCount(CheckerColor color) {
		switch (color)
		case (black) { 
			blackSuccessiveTimeouts = 0;
		}
		case (white) { 
			whiteSuccessiveTimeouts = 0;
		}
	}
	
	function endGame(PlayerId playerId, PlayerId winnerId = systemPlayerId) {
		if (game.end()) {
			matchCommander(EndMatchMessage(playerId, matchId, winnerId, game.score));
			return true;
		} else {
			return false;
		}
	}
	
	function surrenderGame(PlayerId playerId, CheckerColor playerColor) {
		if (exists currentColor = game.currentColor) {
			value opponentId = toPlayerId(playerColor.oppositeColor);
			return endGame(playerId, opponentId);
		} else {
			return endGame(playerId);
		}
	}
	
	function beginNextTurn(Instant timestamp) {
		value nextColor = game.currentColor;
		assert (exists nextColor);
		value roll = diceRoller.roll();
		value factor = roll.isPair then 2 else 1;
		value turnDuration = game.hasAvailableMove(nextColor, roll) then configuration.maxTurnDuration.scale(factor) else configuration.maxEmptyTurnDuration;
		value maxUndo = configuration.maxUndoPerTurn * factor;
		assert (game.beginTurn(nextColor, roll, timestamp, turnDuration, maxUndo));
		messageBroadcaster(StartTurnMessage(matchId, toPlayerId(nextColor), nextColor, roll, turnDuration, maxUndo));
		return true;
	}
	
	function endTurn(CheckerColor playerColor, Instant timestamp) {
		softTimeoutNotified = false;
		
		if (blackSuccessiveTimeouts + whiteSuccessiveTimeouts >= configuration.maxSkippedGameTurn) {
			return endGame(systemPlayerId);
		} else if (blackSuccessiveTimeouts >= configuration.maxSkippedPlayerTurn) {
			return surrenderGame(toPlayerId(black), black);
		} else if (whiteSuccessiveTimeouts >= configuration.maxSkippedPlayerTurn) {
			return surrenderGame(toPlayerId(white), white);
		} else if (blackInvalidMoves > configuration.maxWarningCount) {
			return surrenderGame(toPlayerId(black), black);
		} else if (whiteInvalidMoves > configuration.maxWarningCount) {
			return surrenderGame(toPlayerId(white), white);
		} else if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.endTurn(playerColor)) {
			return beginNextTurn(timestamp);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function undoMoves(CheckerColor playerColor, Instant timestamp) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.undoTurnMoves(playerColor)) {
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
		value roll = diceRoller.roll();
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
		if (game.begin(playerColor)) {
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
		} else if (game.takeTurn(playerColor)) {
			return beginNextTurn(timestamp);
		} else if (game.hasWon(playerColor)) {
			return endGame(toPlayerId(playerColor), toPlayerId(playerColor));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.buildState(timestamp)));
			return false;
		}
	}
	
	function handleMessage(InboundGameMessage message, CheckerColor playerColor) {
		resetPlayerTimeoutCount(playerColor);
		
		switch (message) 
		case (is StartGameMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, sendInitialRoll(message.timestamp));
		}
		case (is PlayerBeginMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, beginGame(playerColor, message.timestamp));
		}
		case (is MakeMoveMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, makeMove(playerColor, message.sourcePosition, message.targetPosition));
		}
		case (is UndoMovesMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, undoMoves(playerColor, message.timestamp));
		}
		case (is EndTurnMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, endTurn(playerColor, message.timestamp));
		}
		case (is EndGameMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, surrenderGame(toPlayerId(playerColor), playerColor));
		}
		case (is TakeTurnMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, takeTurn(playerColor, message.timestamp));
		}
		case (is GameStateRequestMessage) {
			return GameStateResponseMessage(matchId, message.playerId, playerColor, game.buildState(message.timestamp));
		}
	}
	
	void doSoftTimeout(Instant currentTime) {
		softTimeoutNotified = true;
		
		if (exists currentColor = game.currentColor) {
			messageBroadcaster(TurnTimedOutMessage(matchId, toPlayerId(currentColor), currentColor));
		} else {
			if (game.mustRollDice(player1Color)) {
				messageBroadcaster(TurnTimedOutMessage(matchId, player1Id, player1Color));
			}
			if (game.mustRollDice(player2Color)) {
				messageBroadcaster(TurnTimedOutMessage(matchId, player2Id, player2Color));
			}
		}
	}
	
	void doHardTimeout(Instant timestamp) {
		if (exists currentColor = game.currentColor) {
			increasePlayerTimeoutCount(currentColor);
			endTurn(currentColor, timestamp);
		} else {
			endGame(systemPlayerId);
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
	
	function process(InboundGameMessage message, CheckerColor color) {
		variable GameActionResponseMessage|GameStateResponseMessage result;
		if (game.timedOut(message.timestamp.minus(configuration.serverAdditionalTimeout))) {
			result = handleHardTimeout(message, color);
		} else {
			result = handleMessage(message, color);
		}
		
		return result;
	}
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (is GameStateRequestMessage message) {
			try (lock) {
				// TODO cannot determine color
				return GameStateResponseMessage(matchId, message.playerId, player1Color, game.buildState(message.timestamp));
			}
		} else if (exists color = toPlayerColor(message.playerId)) {
			try (lock) {
				return process(message, color);
			}
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(matchId, message.playerId, player1Color, false);
		}
	}
	
	shared Boolean ended {
		try (lock) {
		 	return game.ended;
		 }
	}
}