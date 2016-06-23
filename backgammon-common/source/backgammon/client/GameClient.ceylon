import backgammon.game {
	Game,
	GameConfiguration
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
shared class GameClient(String playerId, GameConfiguration configuration, Anything(InboundGameMessage) messageBroadcaster) {
	value game = Game();
	
	
	
	shared Boolean handleMessage(OutboundGameMessage message) {
		
		switch (message) 
		case (is InitialRollMessage) {
			game.initialRoll(message.roll, message.maxDuration);
			// TODO determine color
		}
		case (is StartTurnMessage) {
			
			//game.beginTurn(, message.roll, message.maxDuration, message.maxUndo);
		}
		case (is PlayedMoveMessage) {}
		case (is UndoneMovesMessage) {}
		case (is InvalidMoveMessage) {}
		case (is DesynchronizedMessage) {}
		case (is NotYourTurnMessage) {}
		case (is GameWonMessage) {}
		case (is GameEndedMessage) {}
		
		return false;
	}
}