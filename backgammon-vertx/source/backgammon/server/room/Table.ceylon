import backgammon.shared {
	TableId,
	RoomId,
	OutboundTableMessage,
	CreatedMatchMessage,
	OutboundMatchMessage,
	PlayerId,
	LeftTableMessage,
	JoinedTableMessage,
	MatchState
}

import ceylon.collection {
	linked,
	HashMap
}

final shared class Table(shared Integer index, shared RoomId roomId, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index);
	
	variable Match? _match = null;
	shared Match? match => _match;
	shared MatchState? matchState => _match?.state;
	
	value playerQueue = HashMap<PlayerId, Player>(linked);
	
	shared Integer queueSize => playerQueue.size;
	
	function createMatch(Player player1, Player player2) {
		value currentMatch = Match(player1, player2, this, messageBroadcaster);
		if (player1.joinMatch(currentMatch) && player2.joinMatch(currentMatch)) {
			_match = currentMatch;
			messageBroadcaster(CreatedMatchMessage(player2.id, currentMatch.id, player1.info, player2.info));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean sitPlayer(Player player) {
		if (playerQueue.defines(player.id)) {
			return false;
		} else if (player.joinTable(this)) {
			messageBroadcaster(JoinedTableMessage(player.id, id));
			if (match exists){
				playerQueue.put(player.id, player);
				return true;
			} else if (exists opponent = playerQueue.first) {
				playerQueue.put(player.id, player);
				return createMatch(opponent.item, player);
			} else {
				playerQueue.put(player.id, player);
				return true;
			}
		} else {
			return false;
		}
	}
	
	function removeFreePlayer(Player player) {
		if (player.leaveTable(id)) {
			playerQueue.remove(player.id);
			messageBroadcaster(LeftTableMessage(player.id, id));
			return true;
		} else {
			return false;
		}
	}
	
	function removeMatchPlayer(Match currentMatch, Player player) {
		_match = null;
		if (currentMatch.gameEnded) {
			return removeFreePlayer(player);
		} else if (currentMatch.end(player.id)) { // this method calls removePlayer
			return true;
		} else {
			_match = currentMatch;
			return false;
		}
	}
	
	shared Boolean removePlayer(Player player) {
		if (player.isAtTable(id)) {
			if (exists currentMatch = match, currentMatch.findPlayer(player.id) exists) {
				return removeMatchPlayer(currentMatch, player);
			} else {
				return removeFreePlayer(player);
			}
		} else {
			return false;
		}
	}

	shared Boolean isInRoom(RoomId roomId) => id.roomId == roomId.roomId;
}
