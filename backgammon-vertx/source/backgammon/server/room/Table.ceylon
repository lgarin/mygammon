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
	HashSet,
	linked
}

final shared class Table(shared Integer index, shared RoomId roomId, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index);
	
	variable Match? match = null;
	
	value playerQueue = HashSet<Player>(linked);
	
	shared Boolean free => playerQueue.empty;
	
	shared Boolean busy => !free;
	
	shared Integer queueSize => playerQueue.size;
	
	shared void publish(OutboundTableMessage|OutboundMatchMessage message) {
		messageBroadcaster(message);
	}

	function createMatch(Player player1, Player player2) {
		value currentMatch = Match(player1, player2, this);
		if (player1.joinMatch(currentMatch) && player2.joinMatch(currentMatch)) {
			match = currentMatch;
			publish(CreatedMatchMessage(player2.id, currentMatch.id, player1.info, player2.info));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean sitPlayer(Player player) {
		if (playerQueue.contains(player)) {
			return false;
		} else if (match exists){
			playerQueue.add(player);
			return false;
		} else if (exists opponent = playerQueue.first) {
			return playerQueue.add(player) && createMatch(opponent, player);
		} else if (playerQueue.empty) {
			return playerQueue.add(player);
		} else {
			playerQueue.add(player);
			return false;
		}
	}
	
	shared Boolean removePlayer(Player player) {
		return playerQueue.remove(player);
	}
	
	shared Boolean removeMatch(Match currentMatch) {
		if (exists matchImpl = match, matchImpl === currentMatch) {
			match = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared MatchState? matchInfo {
		if (exists currentMatch = match) {
			return currentMatch.state;
		} else {
			return null;
		}
	}
	shared Boolean endMatch(MatchId matchId, PlayerId? winnerId) {
		if (exists currentMatch = match, currentMatch.id == matchId) {
			//currentMatch.end(winnerId);
			// TODO announce winner
			removePlayer(currentMatch.player1);
			removePlayer(currentMatch.player2);
			match = null;
			return true;
		} else {
			return false;
		}
	}
}
