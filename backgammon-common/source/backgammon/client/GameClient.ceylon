import backgammon.game {
	Game,
	GameConfiguration
}
import backgammon.common {

	InboundGameMessage,
	OutboundGameMessage,
	InitialRollMessage
}
shared class GameClient(GameConfiguration configuration, Anything(InboundGameMessage) messageBroadcaster) {
	value game = Game();
	
	shared Boolean handleMessage(OutboundGameMessage message) {
		// TODO add timeout in each message
		/*
		switch (message) 
		case (is InitialRollMessage) {
			game.initialRoll(message.roll, configuration.maxRollDuration);
		}
		 */
		return false;
	}
}