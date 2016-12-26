import backgammon.shared {
	TableId,
	RoomId,
	OutboundTableMessage,
	CreatedMatchMessage,
	OutboundMatchMessage,
	PlayerId,
	LeftTableMessage,
	JoinedTableMessage,
	MatchState,
	PlayerInfo
}

import ceylon.collection {
	linked,
	HashMap
}

final shared class Table(shared Integer index, shared RoomId roomId, shared Integer matchBet, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index);
	
	variable Match? _match = null;
	shared MatchState? matchState => _match?.state;
	
	value playerQueue = HashMap<PlayerId, Player>(linked);
	
	shared Integer queueSize => playerQueue.size;
	
	shared [PlayerInfo*] queueState => [for (e in playerQueue.items) e.info]; 
	
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
	
	value firstQueuedPlayer => playerQueue.first?.item;
	value secondQueuedPlayer =>  playerQueue.rest.first?.item;
	
	shared Match? newMatch() {
		if (!_match exists, exists player1 = firstQueuedPlayer, exists player2 = secondQueuedPlayer) {
			createMatch(player1, player2);
			return _match;
		} else {
			return null;
		}
	}
	
	shared Boolean sitPlayer(Player player) {
		if (player.balance < matchBet) {
			return false;
		} else if (playerQueue.defines(player.id)) {
			return false;
		} else if (player.joinTable(this)) {
			messageBroadcaster(JoinedTableMessage(player.id, id, player.info));
			playerQueue.put(player.id, player);
			return true;
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
			if (exists currentMatch = _match, currentMatch.findPlayer(player.id) exists) {
				return removeMatchPlayer(currentMatch, player);
			} else {
				return removeFreePlayer(player);
			}
		} else {
			return false;
		}
	}
}
