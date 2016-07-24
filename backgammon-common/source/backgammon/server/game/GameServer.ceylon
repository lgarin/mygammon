import backgammon.common {
	MatchId,
	PlayerId,
	StartTurnMessage,
	CheckTimeoutMessage,
	DesynchronizedMessage,
	StartGameMessage,
	PlayedMoveMessage,
	UndoneMovesMessage,
	InboundGameMessage,
	GameWonMessage,
	PlayerReadyMessage,
	GameEndedMessage,
	NotYourTurnMessage,
	EndGameMessage,
	MakeMoveMessage,
	OutboundGameMessage,
	InitialRollMessage,
	InvalidMoveMessage,
	UndoMovesMessage,
	EndTurnMessage,
	GameStateResponseMessage,
	GameStateRequestMessage,
	GameActionResponseMessage
}
import backgammon.game {
	GameConfiguration,
	Game,
	black,
	white,
	CheckerColor,
	player1Color,
	player2Color
}
import backgammon.server.common {
	ObtainableLock
}

import ceylon.time {
	Instant,
	now
}

final class GameServer(PlayerId player1Id, PlayerId player2Id, MatchId matchId, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value lock = ObtainableLock(); 
	value diceRoller = DiceRoller();
	variable Integer blackWarnings = 0;
	variable Integer whiteWarnings = 0;
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
	
	function sendInitialRoll() {
		value roll = diceRoller.roll();
		if (game.initialRoll(roll, configuration.maxRollDuration)) {
			messageBroadcaster(InitialRollMessage(matchId, player1Id, player1Color, roll.getValue(player1Color), roll, configuration.maxRollDuration));
			messageBroadcaster(InitialRollMessage(matchId, player2Id, player2Color, roll.getValue(player2Color), roll, configuration.maxRollDuration));
			return true;
		} else {
			return false;
		}
	}
	
	void increaseWarningCount(CheckerColor playerColor, Integer increment) {
		switch (playerColor)
		case (black) {
			blackWarnings += increment;
		}
		case (white) {
			whiteWarnings += increment;
		}
	}
	
	function endTurn(CheckerColor playerColor) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.endTurn(playerColor)) {
			value nextColor = game.currentColor;
			assert (exists nextColor);
			value roll = diceRoller.roll();
			value turnDuration = game.hasAvailableMove(nextColor, roll) then configuration.maxTurnDuration else configuration.maxEmptyTurnDuration;
			assert (game.beginTurn(nextColor, roll, turnDuration, configuration.maxUndoPerTurn));
			messageBroadcaster(StartTurnMessage(matchId, toPlayerId(nextColor), nextColor, roll, turnDuration, configuration.maxUndoPerTurn));
			return true;
		} else if (game.hasWon(playerColor)) {
			messageBroadcaster(GameWonMessage(matchId, toPlayerId(playerColor), playerColor));
			return true;
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.state));
			return false;
		}
	}
	
	function undoMoves(CheckerColor playerColor) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor), playerColor));
			return false;
		} else if (game.undoTurnMoves(playerColor)) {
			messageBroadcaster(UndoneMovesMessage(matchId, toPlayerId(playerColor), playerColor));
			return true;
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.state));
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
			increaseWarningCount(playerColor, configuration.invalidMoveWarningCount);
			messageBroadcaster(InvalidMoveMessage(matchId, toPlayerId(playerColor), playerColor, sourcePosition, targetPosition));
			return false;
		}
	}
	
	function beginGame(CheckerColor playerColor) {
		if (game.begin(playerColor)) {
			if (exists currentColor = game.currentColor) {
				value roll = diceRoller.roll();
				if (game.beginTurn(currentColor, roll, configuration.maxTurnDuration, configuration.maxUndoPerTurn)) {
					messageBroadcaster(StartTurnMessage(matchId, toPlayerId(currentColor), currentColor, roll, configuration.maxTurnDuration, configuration.maxUndoPerTurn));
					return true;
				} else {
					return false;
				}
			} else if (game.started) {
				// first roll was a tie
				return sendInitialRoll();
			} else {
				// first player annouced ready
				return true;
			}
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor), playerColor, game.state));
			return false;
		}
	}
	
	function endGame() {
		if (game.end()) {
			messageBroadcaster(GameEndedMessage(matchId, player1Id, player1Color));
			messageBroadcaster(GameEndedMessage(matchId, player2Id, player2Color));
			return true;
		} else {
			return false;
		}
	}
	
	function surrenderGame(CheckerColor playerColor) {
		if (exists currentColor = game.currentColor) {
			value opponentId = toPlayerId(playerColor.oppositeColor);
			messageBroadcaster(GameWonMessage(matchId, opponentId, playerColor.oppositeColor));
		}
		return endGame();
	}
	
	function handleMessage(InboundGameMessage message, CheckerColor playerColor) {
		switch (message) 
		case (is StartGameMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, sendInitialRoll());
		}
		case (is PlayerReadyMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, beginGame(playerColor));
		}
		case (is MakeMoveMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, makeMove(playerColor, message.sourcePosition, message.targetPosition));
		}
		case (is UndoMovesMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, undoMoves(playerColor));
		}
		case (is EndTurnMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, endTurn(playerColor));
		}
		case (is CheckTimeoutMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, false);
		}
		case (is EndGameMessage) {
			return GameActionResponseMessage(matchId, message.playerId, playerColor, surrenderGame(playerColor));
		}
		case (is GameStateRequestMessage) {
			return GameStateResponseMessage(matchId, message.playerId, playerColor, game.state);
		}
	}
	
	function handleTimeout(InboundGameMessage message, CheckerColor playerColor) {
		if (exists currentColor = game.currentColor) {
			increaseWarningCount(currentColor, configuration.timeoutActionWarningCount);
			endTurn(currentColor);
		} else {
			endGame();
		}
		return GameActionResponseMessage(matchId, message.playerId, playerColor, message is CheckTimeoutMessage);
	}
	
	shared Boolean isInactive(Instant currentTime) {
		return game.timedOut(currentTime.minus(configuration.gameInactiveTimeout));
	}
	
	function process(InboundGameMessage message, Instant currentTime, CheckerColor color) {
		variable GameActionResponseMessage|GameStateResponseMessage result;
		if (game.timedOut(currentTime.minus(configuration.serverAdditionalTimeout))) {
			result = handleTimeout(message, color);
		} else {
			result = handleMessage(message, color);
		}
		if (blackWarnings > configuration.maxWarningCount) {
			surrenderGame(black);
		} else if (whiteWarnings > configuration.maxWarningCount) {
			surrenderGame(white);
		}
		return result;
	}
	
	shared GameActionResponseMessage|GameStateResponseMessage processGameMessage(InboundGameMessage message) {
		if (exists color = toPlayerColor(message.playerId)) {
			Instant currentTime = now();
			try (lock) {
				return process(message, currentTime, color);
			}
		} else {
			// TODO cannot determine color
			return GameActionResponseMessage(matchId, message.playerId, player1Color, false);
		}
	}
}