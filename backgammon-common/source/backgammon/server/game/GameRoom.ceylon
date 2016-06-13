import backgammon.server.common {

	RoomConfiguration
}
import ceylon.collection {

	HashMap
}
import backgammon.common {

	OutboundGameMessage,
	MatchId,
	InboundGameMessage,
	StartGameMessage,
	EndGameMessage
}
import ceylon.time {

	Instant
}

shared final class GameRoom(RoomConfiguration configuration, Anything(OutboundGameMessage) messageBroadcaster) {
	
	value gameMap = HashMap<MatchId, GameServer>();
	
	shared Boolean processMessage(InboundGameMessage message, Instant currentTime) {
		// TODO implement flooding control
		
		if (exists currentServer = gameMap[message.matchId]) {
			if (is EndGameMessage message) {
				gameMap.remove(message.matchId);
			}
			return currentServer.processGameMessage(message, currentTime);
		} else if (is StartGameMessage message) {
			value server = GameServer(message.playerId, message.opponentId, message.matchId, configuration, messageBroadcaster);
			gameMap.put(message.matchId, server);
			return server.processGameMessage(message, currentTime);
		} else {
			return false;
		}
	}
	
	shared void removeInactiveGames(Instant currentTime) {
		
	}
}