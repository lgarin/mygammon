import backgammon.game {

	GameConfiguration,
	Game,
	InitialRollMessage,
	InboundGameMessage,
	OutboundGameMessage,
	AcknowledgeRollMessage,
	StartTurnMessage,
	MakeMoveMessage,
	PlayedMoveMessage,
	InvalidMoveMessage,
	UndoMovesMessage,
	UndoneMovesMessage,
	InvalidStateMessage,
	EndTurnMessage,
	GameWonMessage
}
import ceylon.time {

	now
}


shared class GameServer(String player1Id, String player2Id, String gameId, GameConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value diceRoller = DiceRoller();
	
	value game = Game(player1Id, player2Id, gameId);
	
	shared Boolean sendInitialRoll() {
		value roll = diceRoller.roll();
		if (game.initialRoll(roll, configuration.maxRollDuration)) {
			messageBroadcaster(InitialRollMessage(gameId, player1Id, roll.firstValue));
			messageBroadcaster(InitialRollMessage(gameId, player2Id, roll.secondValue));
			return true;
		}
		return false;
	}
	
	void processMessage(InboundGameMessage message) {
		if (message.gameId != gameId) {
			return;
		}
		
		if (game.timedOut(now())) {
			
		}
		
		switch (message) 
		case (is AcknowledgeRollMessage) {
			if (game.endInitialRoll(message.playerId)) {
				if (exists currentPlayerId = game.currentPlayerId) {
					value roll = diceRoller.roll();
					game.beginTurn(currentPlayerId, roll, configuration.maxTurnDuration);
					messageBroadcaster(StartTurnMessage(gameId, currentPlayerId, roll));
				} else {
					sendInitialRoll();
				}
			}
		}
		case (is MakeMoveMessage) {
			if (game.moveChecker(message.playerId, message.move.sourcePosition, message.move.targetPosition)) {
				messageBroadcaster(PlayedMoveMessage(gameId, message.playerId, message.move));
			} else {
				messageBroadcaster(InvalidMoveMessage(gameId, message.playerId, message.move));
			}
		}
		case (is UndoMovesMessage) {
			if (game.undoTurnMoves(message.playerId)) {
				messageBroadcaster(UndoneMovesMessage(gameId, message.playerId));
			} else {
				messageBroadcaster(InvalidStateMessage(gameId, message.playerId));
			}
		}
		case (is EndTurnMessage) {
			if (game.endTurn(message.playerId)) {
				// TODO what if the next player has no possible move?
				if (exists nextPlayer = game.switchTurn(message.playerId)) {
					value roll = diceRoller.roll();
					game.beginTurn(nextPlayer, roll, configuration.maxTurnDuration);
					messageBroadcaster(StartTurnMessage(gameId, nextPlayer, roll));
				} else {
					messageBroadcaster(GameWonMessage(gameId, message.playerId));
				}
			} else {
				messageBroadcaster(InvalidStateMessage(gameId, message.playerId));
			}
		}
		else {
			
		}
	}
}