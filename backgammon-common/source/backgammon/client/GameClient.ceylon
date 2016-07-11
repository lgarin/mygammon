import backgammon.game {
	Game,
	GameConfiguration,
	CheckerColor
}
import backgammon.common {

	InboundGameMessage,
	OutboundGameMessage,
	InitialRollMessage,
	PlayedMoveMessage,
	StartTurnMessage,
	UndoneMovesMessage,
	InvalidMoveMessage,
	DesynchronizedMessage,
	NotYourTurnMessage,
	GameWonMessage,
	GameEndedMessage
}
shared class GameClient(String playerId, Anything(InboundGameMessage) messageBroadcaster) {
	value game = Game();

	
	variable Integer? initialDiceValue = null;
	variable CheckerColor? playerColor = null;
	
	
	
	shared Boolean handleMessage(OutboundGameMessage message) {
		
		switch (message) 
		case (is InitialRollMessage) {
			if (message.playerId == playerId) {
				game.initialRoll(message.roll, message.maxDuration);
				initialDiceValue = message.diceValue;
				playerColor = message.playerColor;
				// TODO start timer
			} else {
				// TODO show opponent dice
			}
			return true;
		}
		case (is StartTurnMessage) {
			game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo);
			// TODO show roll + start timer
			return true;
		}
		case (is PlayedMoveMessage) {
			game.moveChecker(message.playerColor, message.move.sourcePosition, message.move.targetPosition);
			return true;
		}
		case (is UndoneMovesMessage) {
			game.undoTurnMoves(message.playerColor);
			return true;
		}
		case (is InvalidMoveMessage) {
			// TODO restore state
		}
		case (is DesynchronizedMessage) {
			// TODO restore state
		}
		case (is NotYourTurnMessage) {
			// TODO restore state
		}
		case (is GameWonMessage) {
			// TODO stop timer
			if (message.playerId == playerId) {
				// TODO show win
			} else {
				// TODO show lost
			}
			return true;
		}
		case (is GameEndedMessage) {
			return true;
		}
		
		return false;
	}
}