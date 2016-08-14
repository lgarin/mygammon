import backgammon.shared {
	TableId,
	RoomId,
	OutboundTableMessage,
	MatchState,
	CreatedMatchMessage,
	OutboundMatchMessage,
	MatchId,
	PlayerId
}

import ceylon.collection {
	linked,
	HashMap
}
import ceylon.time {
	now
}

final shared class Table(shared Integer index, shared RoomId roomId, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index);
	
	variable MatchState? match = null;
	
	shared MatchId? matchId => match?.id;
	
	value playerQueue = HashMap<PlayerId, Player>(linked);
	
	shared Boolean free => playerQueue.empty;
	
	shared Boolean busy => !free;
	
	shared Integer queueSize => playerQueue.size;
	
	shared void publish(OutboundTableMessage|OutboundMatchMessage message) {
		messageBroadcaster(message);
	}

	function createMatch(Player player1, Player player2) {
		value matchId = MatchId(id, now());
		value currentMatch = MatchState(matchId, player1.info, player2.info);
		if (player1.joinMatch(currentMatch) && player2.joinMatch(currentMatch)) {
			match = currentMatch;
			publish(CreatedMatchMessage(player2.id, currentMatch.id, player1.info, player2.info));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean sitPlayer(Player player) {
		if (playerQueue.defines(player.id)) {
			return false;
		} else if (player.joinTable(this)) {
			if (match exists){
				playerQueue.put(player.id, player);
				return false;
			} else if (exists opponent = playerQueue.first) {
				playerQueue.put(player.id, player);
				return createMatch(opponent.item, player);
			} else if (playerQueue.empty) {
				playerQueue.put(player.id, player);
				return true;
			} else {
				playerQueue.put(player.id, player);
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared Player? removePlayer(PlayerId playerId) {
		if (exists player = playerQueue[playerId]) {
			// TODO ugly
			if (exists currentMatch = match, exists opponentId = currentMatch.opponentId(playerId), exists opponent = playerQueue[opponentId]) {
				if (!opponent.leaveTable()) {
					return null;
				} else {
					playerQueue.remove(opponentId);
				}
			}
			if (player.leaveTable()) {
				playerQueue.remove(playerId);
				return player;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}

	shared MatchState? getTableMatch(PlayerId playerId) {
		if (exists player = playerQueue[playerId]) {
			return match;
		} else {
			return null;
		}
	}
	
	shared MatchState? endMatch(MatchId matchId, PlayerId? winnerId) {
		if (exists currentMatch = match, currentMatch.id == matchId) {
			currentMatch.winnerId = winnerId;
			removePlayer(currentMatch.player1Id);
			removePlayer(currentMatch.player2Id);
			match = null;
			return currentMatch;
		} else {
			return null;
		}
	}
	
	shared MatchState? acceptMatch(MatchId matchId, PlayerId playerId) {
		if (exists currentMatch = match, currentMatch.id == matchId, exists player = playerQueue[playerId]) {
			if (player.acceptMatch(matchId)) {
				return currentMatch;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
}
