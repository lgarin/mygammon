import backgammon.shared {
	PlayerId,
	MatchId,
	MatchState,
	MatchEndedMessage,
	AcceptedMatchMessage,
	OutboundMatchMessage,
	systemPlayerId
}

import ceylon.time {
	now
}

shared class Match(shared Player player1, shared Player player2, shared Table table, Anything(OutboundMatchMessage) messageBroadcaster) {
	
	value creationTime = now();
	shared MatchId id = MatchId(table.id, creationTime);

	shared MatchState state = MatchState(id, player1.info, player2.info);

	shared Boolean gameStarted => state.gameStarted;
	shared Boolean gameEnded => state.gameEnded;
	shared Boolean hasGame => state.gameStarted && !state.gameEnded;
	
	shared Player? findPlayer(PlayerId playerId) {
		if (player1.id == playerId) {
			return player1;
		} else if (player2.id == playerId) {
			return player2;
		} else {
			return null;
		}
	}
	
	shared Player? findOpponent(PlayerId playerId) {
		if (player1.id == playerId) {
			return player2;
		} else if (player2.id == playerId) {
			return player1;
		} else {
			return null;
		}
	}

	shared Boolean markReady(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			if (player.acceptMatch(id) && state.markReady(playerId)) {
				messageBroadcaster(AcceptedMatchMessage(playerId, id));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	void endGame(PlayerId playerId, PlayerId winnerId) {
		state.end(playerId, winnerId);		
		messageBroadcaster(MatchEndedMessage(playerId, id, winnerId));
		table.removePlayer(player1.id);
		table.removePlayer(player2.id);
	}

	shared Boolean end(PlayerId playerId, PlayerId? winnerId) {
		if (gameEnded) {
			return false;
		} else if (!gameStarted) {
			endGame(playerId, systemPlayerId);
			return true;
		} else if (exists winnerId) {
			// call from game server
			endGame(playerId, winnerId);
			return true;
		} else {
			// call from leave table
			// will trigger a EndGameMessage in match room
			table.removePlayer(player1.id);
			table.removePlayer(player2.id);
			return true;
		}
	}
}
