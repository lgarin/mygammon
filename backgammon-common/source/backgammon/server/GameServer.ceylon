import backgammon.game {

	GameConfiguration,
	Game,
	InitialRollMessage,
	InboundGameMessage,
	OutboundGameMessage,
	PlayerReadyMessage,
	StartTurnMessage,
	MakeMoveMessage,
	PlayedMoveMessage,
	InvalidMoveMessage,
	UndoMovesMessage,
	UndoneMovesMessage,
	InvalidStateMessage,
	EndTurnMessage,
	GameWonMessage,
	CheckTimeoutMessage,
	NotYourTurnMessage,
	GameMove,
	EndGameMessage,
	GameEndedMessage
}
import ceylon.time {

	Instant
}

shared class GameServer(String player1Id, String player2Id, String gameId, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value diceRoller = DiceRoller();
	variable Integer player1Warnings = 0;
	variable Integer player2Warnings = 0;
	value game = Game(player1Id, player2Id, gameId);
	
	shared Boolean sendInitialRoll() {
		value roll = diceRoller.roll();
		if (game.initialRoll(roll, configuration.maxRollDuration)) {
			messageBroadcaster(InitialRollMessage(gameId, player1Id, roll.firstValue));
			messageBroadcaster(InitialRollMessage(gameId, player2Id, roll.secondValue));
			return true;
		} else {
			messageBroadcaster(InvalidStateMessage(gameId, player1Id));
			messageBroadcaster(InvalidStateMessage(gameId, player2Id));
			return false;
		}
	}
	
	void increaseWarningCount(String playerId, Integer increment) {
		if (playerId == player1Id) {
			player1Warnings += 1;
		} else if (playerId == player2Id) {
			player2Warnings += 1;
		}
	}
	
	void endTurn(String playerId) {
		if (!game.isCurrentPlayer(playerId)) {
			messageBroadcaster(NotYourTurnMessage(gameId, playerId));
		} else if (game.endTurn(playerId)) {
			if (exists nextPlayerId = game.switchTurn(playerId)) {
				value roll = diceRoller.roll();
				value turnDuration = game.hasAvailableMove(nextPlayerId) then configuration.maxTurnDuration else configuration.maxEmptyTurnDuration;
				assert (game.beginTurn(nextPlayerId, roll, turnDuration));
				messageBroadcaster(StartTurnMessage(gameId, nextPlayerId, roll));
			} else if (game.hasWon(playerId)) {
				messageBroadcaster(GameWonMessage(gameId, playerId));
			}
		} else {
			messageBroadcaster(InvalidStateMessage(gameId, playerId));
		}
	}
	
	void undoMoves(String playerId) {
		if (!game.isCurrentPlayer(playerId)) {
				messageBroadcaster(NotYourTurnMessage(gameId, playerId));
			} else if (game.undoTurnMoves(playerId)) {
				messageBroadcaster(UndoneMovesMessage(gameId, playerId));
			} else {
				messageBroadcaster(InvalidStateMessage(gameId, playerId));
			}
	}
	
	void makeMove(String playerId, GameMove move) {
		if (!game.isCurrentPlayer(playerId)) {
				messageBroadcaster(NotYourTurnMessage(gameId, playerId));
			} else if (game.moveChecker(playerId, move.sourcePosition, move.targetPosition)) {
				messageBroadcaster(PlayedMoveMessage(gameId, playerId, move));
			} else {
				increaseWarningCount(playerId, configuration.invalidMoveWarningCount);
				messageBroadcaster(InvalidMoveMessage(gameId, playerId, move));
			}
	}
	
	void beginGame(String playerId) {
		if (game.begin(playerId)) {
			if (exists currentPlayerId = game.currentPlayerId) {
				value roll = diceRoller.roll();
				assert (game.beginTurn(currentPlayerId, roll, configuration.maxTurnDuration));
				messageBroadcaster(StartTurnMessage(gameId, currentPlayerId, roll));
			} else {
				sendInitialRoll();
			}
		} else {
			messageBroadcaster(InvalidStateMessage(gameId, playerId));
		}
	}
	
	function isGamePlayer(String playerId) => playerId == player1Id || playerId == player2Id;
	
	shared void surrenderGame(String playerId) {
		if (!isGamePlayer(playerId)) {
			return;
		}
		
		if (exists currentPlayerId = game.currentPlayerId) {
			value opponentId = playerId == player1Id then player2Id else player1Id;
			messageBroadcaster(GameWonMessage(gameId, opponentId));
		}
		endGame();
	}
	
	void endGame() {
		if (game.end()) {
			messageBroadcaster(GameEndedMessage(gameId, player1Id));
			messageBroadcaster(GameEndedMessage(gameId, player2Id));
		}
	}
	
	void handleMessage(InboundGameMessage message) {
		switch (message) 
		case (is PlayerReadyMessage) {
			beginGame(message.playerId);
		}
		case (is MakeMoveMessage) {
			makeMove(message.playerId, message.move);
		}
		case (is UndoMovesMessage) {
			undoMoves(message.playerId);
		}
		case (is EndTurnMessage) {
			endTurn(message.playerId);
		}
		case (is CheckTimeoutMessage) {
			
		}
		case (is EndGameMessage) {
			surrenderGame(message.playerId);
		}
	}
	
	shared void processMessage(InboundGameMessage message, Instant currentTime) {
		if (!isGamePlayer(message.playerId)) {
			return;
		}
		
		if (game.timedOut(currentTime.minus(configuration.serverAdditionalTimeout))) {
			if (exists playerId = game.currentPlayerId) {
				increaseWarningCount(playerId, configuration.timeoutActionWarningCount);
				endTurn(playerId);
			} else {
				endGame();
			}
		} else {
			handleMessage(message);
		}
		
		if (player1Warnings > configuration.maxWarningCount) {
			surrenderGame(player1Id);
		} else if (player2Warnings > configuration.maxWarningCount) {
			surrenderGame(player2Id);
		}
	}
}