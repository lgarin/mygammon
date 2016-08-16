import backgammon.shared {
	TableId,
	RoomId,
	OutboundTableMessage,
	MatchState,
	CreatedMatchMessage,
	OutboundMatchMessage,
	MatchId,
	PlayerId,
	LeftTableMessage,
	JoinedTableMessage
}

import ceylon.collection {
	linked,
	HashMap
}

final shared class Table(shared Integer index, shared RoomId roomId, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index);
	
	variable Match? _match = null;
	shared Match? match => _match;
	
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
			} else if (playerQueue.empty) {
				playerQueue.put(player.id, player);
				return true;
			} else {
				playerQueue.put(player.id, player);
				return true;
			}
		} else {
			return false;
		}
	}
	
	shared Player? removePlayer(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			if (exists currentMatch = match) {
				_match = null;
				if (currentMatch.end(playerId, null)) {
					return player;
				} else {
					_match = currentMatch;
					return null;
				}
			} else if (player.leaveTable(id)) {
				playerQueue.remove(playerId);
				messageBroadcaster(LeftTableMessage(player.id, id));
				return player;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}

	shared MatchState? getMatchState(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			return match?.state;
		} else {
			return null;
		}
	}

	shared Match? findMatch(MatchId matchId) {
		if (exists currentMatch = match, currentMatch.id == matchId) {
			return match;
		} else {
			return null;
		}
	}
	
	shared Player? findPlayer(PlayerId playerId) {
		if (exists player = playerQueue[playerId], player.isAtTable(id)) {
			return player;
		} else {
			return null;
		}
	}
	
	shared Boolean isInRoom(RoomId roomId) => id.roomId == roomId.roomId;
}
