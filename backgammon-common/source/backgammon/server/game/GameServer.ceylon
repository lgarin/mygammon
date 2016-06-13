import backgammon.game {
	GameConfiguration,
	Game,
	GameMove,
	black,
	white,
	CheckerColor
}
import ceylon.time {

	Instant
}
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
	EndTurnMessage
}
import backgammon.server.common {

	ObtainableLock
}

final class GameServer(PlayerId player1Id, PlayerId player2Id, MatchId matchId, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value lock = ObtainableLock(); 
	value diceRoller = DiceRoller();
	variable Integer blackWarnings = 0;
	variable Integer whiteWarnings = 0;
	value game = Game();
	
	function toPlayerColor(PlayerId playerId) {
		if (playerId == player1Id) {
			return black;
		} else if (playerId == player2Id) {
			return white;
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
			messageBroadcaster(InitialRollMessage(matchId, player1Id, roll.firstValue));
			messageBroadcaster(InitialRollMessage(matchId, player2Id, roll.secondValue));
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
	
	void endTurn(CheckerColor playerColor) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor)));
		} else if (game.endTurn(playerColor)) {
			if (exists nextColor = game.switchTurn(playerColor)) {
				value roll = diceRoller.roll();
				value turnDuration = game.hasAvailableMove(nextColor) then configuration.maxTurnDuration else configuration.maxEmptyTurnDuration;
				assert (game.beginTurn(nextColor, roll, turnDuration));
				messageBroadcaster(StartTurnMessage(matchId, toPlayerId(nextColor), roll));
			} else if (game.hasWon(playerColor)) {
				messageBroadcaster(GameWonMessage(matchId, toPlayerId(playerColor)));
			}
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor)));
		}
	}
	
	void undoMoves(CheckerColor playerColor) {
		// TODO limit the number of undo per turn
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor)));
		} else if (game.undoTurnMoves(playerColor)) {
			messageBroadcaster(UndoneMovesMessage(matchId, toPlayerId(playerColor)));
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor)));
		}
	}
	
	void makeMove(CheckerColor playerColor, GameMove move) {
		if (!game.isCurrentColor(playerColor)) {
			messageBroadcaster(NotYourTurnMessage(matchId, toPlayerId(playerColor)));
		} else if (game.moveChecker(playerColor, move.sourcePosition, move.targetPosition)) {
			messageBroadcaster(PlayedMoveMessage(matchId, toPlayerId(playerColor), move));
		} else {
			increaseWarningCount(playerColor, configuration.invalidMoveWarningCount);
			messageBroadcaster(InvalidMoveMessage(matchId, toPlayerId(playerColor), move));
		}
	}
	
	void beginGame(CheckerColor playerColor) {
		if (game.begin(playerColor)) {
			if (exists currentColor = game.currentColor) {
				value roll = diceRoller.roll();
				assert (game.beginTurn(currentColor, roll, configuration.maxTurnDuration));
				messageBroadcaster(StartTurnMessage(matchId, toPlayerId(currentColor), roll));
			} else {
				sendInitialRoll();
			}
		} else {
			messageBroadcaster(DesynchronizedMessage(matchId, toPlayerId(playerColor)));
		}
	}
	
	void surrenderGame(CheckerColor playerColor) {
		if (exists currentColor = game.currentColor) {
			value opponentId = toPlayerId(playerColor.oppositeColor);
			messageBroadcaster(GameWonMessage(matchId, opponentId));
		}
		endGame();
	}
	
	void endGame() {
		if (game.end()) {
			messageBroadcaster(GameEndedMessage(matchId, player1Id));
			messageBroadcaster(GameEndedMessage(matchId, player2Id));
		}
	}
	
	void handleMessage(InboundGameMessage message, CheckerColor playerColor) {
		switch (message) 
		case (is StartGameMessage) {
			sendInitialRoll();
		}
		case (is PlayerReadyMessage) {
			beginGame(playerColor);
		}
		case (is MakeMoveMessage) {
			makeMove(playerColor, message.move);
		}
		case (is UndoMovesMessage) {
			undoMoves(playerColor);
		}
		case (is EndTurnMessage) {
			endTurn(playerColor);
		}
		case (is CheckTimeoutMessage) {
			// does nothing timeout are checked in processMessage
		}
		case (is EndGameMessage) {
			surrenderGame(playerColor);
		}
	}
	
	void handleTimeout() {
		if (exists currentColor = game.currentColor) {
			increaseWarningCount(currentColor, configuration.timeoutActionWarningCount);
			endTurn(currentColor);
		} else {
			endGame();
		}
	}
	
	function process(InboundGameMessage message, Instant currentTime, CheckerColor color) {
		if (game.timedOut(currentTime.minus(configuration.serverAdditionalTimeout))) {
			handleTimeout();
		} else {
			handleMessage(message, color);
		}
		if (blackWarnings > configuration.maxWarningCount) {
			surrenderGame(black);
		} else if (whiteWarnings > configuration.maxWarningCount) {
			surrenderGame(white);
		}
		return true;
	}
	
	shared Boolean processGameMessage(InboundGameMessage message, Instant currentTime) {
		if (exists color = toPlayerColor(message.playerId)) {
			try (lock) {
				return process(message, currentTime, color);
			}
		} else {
			return false;
		}
	}
}