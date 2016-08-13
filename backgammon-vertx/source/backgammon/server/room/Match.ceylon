import backgammon.shared {
	PlayerId,
	MatchId,
	MatchState,
	AcceptedMatchMessage,
	LeftMatchMessage,
	CreatedGameMessage,
	GameWonMessage,
	GameMessage,
	GameEndedMessage
}

import ceylon.time {
	Instant,
	now
}

shared class Match(shared Player player1, shared Player player2, shared Table table) {
	
	Instant creationTime = now();
	
	shared MatchId id = MatchId(table.id, creationTime);
	
	value noWinnerId = PlayerId("");
	variable PlayerId? winnerId = null;
	variable Boolean player1Ready = false;
	variable Boolean player2Ready = false;
	
	shared MatchState state => MatchState(id, player1.info, player2.info, player1Ready, player2Ready, winnerId);
	
	shared Boolean isStarted => player1Ready && player2Ready;
	shared Boolean isEnded => winnerId exists;

	shared Boolean end(Player player) {
		if (winnerId exists) {
			return false;
		} else if (player == player1 || player == player2) {
			if (isStarted) {
				player1Ready = false;
				player2Ready = false;
			}
			
			if (table.removeMatch(this)) {
				if (winnerId is Null) {
					winnerId = noWinnerId;
				}
				table.publish(LeftMatchMessage(player.id, id));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	function markReady(Player player) {
		if (isStarted || winnerId exists) {
			return false;
		} else if (player == player1) {
			player1Ready = true;
			return true;
		} else if (player == player2) {
			player2Ready = true;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean processGameMessage(GameMessage message) {
		if (id == message.matchId) {
			if (is GameWonMessage message) {
				winnerId = message.playerId;
			} else if (is GameEndedMessage message) {
				if (winnerId is Null) {
					winnerId = noWinnerId;
				}
				table.removeMatch(this);
			}
			return true;
		} else {
			return false;
		}
		
	}

	shared Boolean acceptMatch(Player player) {
		if (markReady(player)) {
			table.publish(AcceptedMatchMessage(player.id, id));
			if (isStarted) {
				table.publish(CreatedGameMessage(player.id, id));
			}
			return true;
		} else {
			return false;
		}
	}
	
	shared PlayerId? opponentId(PlayerId playerId) {
		if (playerId == player1.id) {
			return player2.id;
		} else if (playerId == player2.id) {
			return player1.id;
		} else {
			return null;
		}
	}
}
