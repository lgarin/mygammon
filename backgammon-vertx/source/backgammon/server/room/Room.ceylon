import backgammon.shared {
	RoomId,
	PlayerId,
	OutboundTableMessage,
	PlayerInfo,
	OutboundMatchMessage,
	TableId,
	MatchId,
	PlayerListMessage,
	PlayerState,
	PlayerStatistic
}

import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked,
	HashSet
}
import ceylon.time {
	Instant
}

final shared class Room(shared String roomId, shared RoomSize maxSize, shared MatchBet matchBet, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared RoomId id = RoomId(roomId);
	
	variable Integer _createdPlayerCount = 0;
	variable Integer _maxPlayerCount = 0;
	value playerMap = HashMap<PlayerId, Player>(unlinked);
	
	value newPlayers = ArrayList<Player>(maxSize.playerCount);
	value updatedPlayers = HashSet<Player>(unlinked);
	value oldPlayers = ArrayList<Player>(maxSize.playerCount);
	
	variable Integer _maxTableCount = 0;
	value tableList = ArrayList<Table>(maxSize.tableCount);
	for (i in 0:maxSize.tableCount) {
		tableList.add(Table(i + 1, id, matchBet.playerBet, messageBroadcaster));
	}
	
	variable Integer _createdMatchCount = 0;
	variable Integer _maxMatchCount = 0;
	value matchMap = HashMap<MatchId, Match>(unlinked);
	
	shared Integer createdMatchCount => _createdMatchCount;
	shared Integer matchCount => matchMap.size;
	shared Integer maxMatchCount {
		if (_maxMatchCount < matchCount) {
			_maxMatchCount = matchCount;
		}
		return _maxMatchCount;
	}
	
	shared Integer createdPlayerCount => _createdPlayerCount;
	shared Integer playerCount => playerMap.size;
	shared Integer maxPlayerCount {
		if (_maxPlayerCount < playerCount) {
			_maxPlayerCount = playerCount;
		}
		return _maxPlayerCount;
	}
	shared Integer busyPlayerCount => playerMap.count((element) => element.item.isPlaying());
	
	shared Integer freeTableCount => tableList.count((table) => table.queueSize == 0);
	shared Integer maxTableCount {
		value busyTableCount = maxSize.tableCount - freeTableCount;
		if (_maxTableCount < busyTableCount) {
			_maxTableCount = busyTableCount;
		}
		return _maxTableCount;
	}
	
	shared Boolean createMatch(Table table) {
		if (exists match = table.newMatch(matchBet.matchPot)) {
			_createdMatchCount++;
			matchMap.put(match.id, match);
			return true;
		} else {
			return false;
		}
	}

	function openTable(Player player) {
		if (exists table = tableList.find((table) => table.queueSize == 0 && table.sitPlayer(player))) {
			return table;
		}
		return null;
	}
	
	function sitPlayer(Player player) {
		if (exists table = tableList.find((table) => table.queueSize == 1 && table.sitPlayer(player))) {
			createMatch(table);
			return table;
		}
		return openTable(player);
	}
	
	shared Boolean removePlayer(Player player) {
		if (exists table = player.table) {
			updatedPlayers.add(player);
			table.removePlayer(player);
			createMatch(table);
		}
		playerMap.remove(player.id);
		oldPlayers.add(player);
		return true;
	}
	
	shared Integer removeInactivePlayers(Instant timeoutTime) {
		variable value result = 0;
		for (player in playerMap.items.clone()) {
			if (!player.isPlaying() && player.isInactiveSince(timeoutTime)) {
				removePlayer(player);
				result++;
			}
		}
		return result;
	}
	
	shared Player? definePlayer(PlayerInfo info, PlayerStatistic statistic) {
		if (exists player = findPlayer(PlayerId(info.id))) {
			return player;
		} else if (playerMap.size >= maxSize.playerCount) {
			return null;
		} else {
			value player = Player(info, statistic);
			playerMap.put(player.id, player);
			newPlayers.add(player);
			_createdPlayerCount++;
			return player;
		}
	}
	
	shared void registerPlayerChange(Player player) {
		if (playerMap.defines(player.id)) {
			updatedPlayers.add(player);
		}
	}
	
	shared Table? findMatchTable(Player player) {
		if (exists table = player.table) {
			return table;
		} else if (!player.table exists) {
			return sitPlayer(player);
		} else {
			return null;
		}
	}
	
	shared Table? findEmptyTable(Player player) {
		if (exists table = player.table) {
			if (player.isPlaying()) {
				return null;
			} else if (table.queueSize == 1) {
				return table;
			} else if (table.removePlayer(player)) {
				return openTable(player);
			} else {
				return null;
			}
		} else if (!player.table exists) {
			return openTable(player);
		} else {
			return null;
		}
	}
	
	shared Table? findTable(TableId tableId) {
		if (tableId.roomId == roomId) {
			return tableList[tableId.table - 1];
		} else {
			return null;
		}
	}
	
	shared Boolean removeMatch(Match match) {
		if (!match.gameEnded) {
			return false;
		} else if (exists table = findTable(match.tableId)) {
			createMatch(table);
		}
		return matchMap.remove(match.id) exists;
	}
	
	shared Match? findMatch(MatchId matchId) {
		return matchMap[matchId];
	}

	shared Player? findPlayer(PlayerId playerId) =>  playerMap[playerId];
	
	shared Integer playerListDeltaSize => newPlayers.size + oldPlayers.size + updatedPlayers.size; 
	
	shared PlayerListMessage createPlayerListDelta() {
		updatedPlayers.removeAll(newPlayers);
		updatedPlayers.removeAll(oldPlayers);
		value message = PlayerListMessage(id, [for (element in newPlayers) element.state], [for (element in oldPlayers) element.state], [for (element in updatedPlayers) element.state]);
		newPlayers.clear();
		oldPlayers.clear();
		updatedPlayers.clear();
		return message;
	}
	
	shared [PlayerState*] createPlayerList() {
		return [for (element in playerMap.items) element.state];
	}
	
}