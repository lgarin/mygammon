import backgammon.shared {
	PlayerId,
	MatchId,
	MatchState,
	MatchEndedMessage,
	AcceptedMatchMessage,
	OutboundMatchMessage,
	systemPlayerId,
	TableId,
	MatchBalance
}

import ceylon.time {
	now
}

shared class Match(shared Player player1, shared Player player2, Table table, Integer matchPot, Anything(OutboundMatchMessage) messageBroadcaster) {
	
	value creationTime = now();
	shared MatchId id = MatchId(table.id, creationTime);
	shared TableId tableId = table.id;
	shared Integer playerBet = table.playerBet;

	shared MatchBalance balance = MatchBalance(playerBet, matchPot, player1.balance, player2.balance);
	shared MatchState state = MatchState(id, player1.info, player2.info, balance);

	shared Boolean gameStarted => state.gameStarted;
	shared Boolean gameEnded => state.gameEnded;
	shared Boolean hasGame => state.hasGame;
	
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
		if (exists player = findPlayer(playerId), player.isInMatch(id), player.balance >= playerBet, state.markReady(playerId)) {
			messageBroadcaster(AcceptedMatchMessage(playerId, id));
			if (gameStarted) {
				player1.placeBet(playerBet);
				player2.placeBet(playerBet);
			}
			return true;
		} else {
			return false;
		}
	}
	
	void endGame(PlayerId playerId, PlayerId winnerId, Integer score) {
		state.end(playerId, winnerId, score);		
		messageBroadcaster(MatchEndedMessage(playerId, id, winnerId, score));
		table.removePlayer(player1);
		table.removePlayer(player2);
	}

	void updatePlayerStatistics(PlayerId winnerId, Integer score) {
		player1.increasePlayedGame();
		player2.increasePlayedGame();
		if (exists winner = findPlayer(winnerId)) {
			winner.increaseWonGame(score, matchPot);
		}
	}
	
	shared Boolean end(PlayerId playerId, PlayerId? winnerId = null, Integer score = 0) {
		if (gameEnded) {
			return false;
		} else if (!gameStarted) {
			endGame(playerId, systemPlayerId, score);
			return true;
		} else if (exists winnerId) {
			// call from game server
			endGame(playerId, winnerId, score);
			updatePlayerStatistics(winnerId, score);
			return true;
		} else {
			// call from leave table
			// will trigger a EndGameMessage in match room
			table.removePlayer(player1);
			table.removePlayer(player2);
			return true;
		}
	}
}
