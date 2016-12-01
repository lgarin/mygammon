import backgammon.shared {
	RoomId,
	PlayerId,
	OutboundTableMessage,
	PlayerInfo,
	OutboundMatchMessage,
	TableId,
	MatchId,
	MatchState,
	PlayerListMessage,
	PlayerState
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

final shared class Room(shared String roomId, shared Integer tableCountLimit, shared Integer playerCountLimit, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared RoomId id = RoomId(roomId);
	
	variable Integer _createdPlayerCount = 0;
	variable Integer _maxPlayerCount = 0;
	value playerMap = HashMap<PlayerId, Player>(unlinked);
	
	value newPlayers = ArrayList<Player>(playerCountLimit);
	value updatedPlayers = HashSet<Player>(unlinked);
	value oldPlayers = ArrayList<Player>(playerCountLimit);
	
	variable Integer _maxTableCount = 0;
	value tableList = ArrayList<Table>(tableCountLimit);
	for (i in 0:tableCountLimit) {
		tableList.add(Table(i + 1, id, messageBroadcaster));
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
		value busyTableCount = tableCountLimit - freeTableCount;
		if (_maxTableCount < busyTableCount) {
			_maxTableCount = busyTableCount;
		}
		return _maxTableCount;
	}
	
	function openTable(Player player) {
		if (exists table = tableList.find((table) => table.queueSize == 0), table.sitPlayer(player)) {
			updatedPlayers.add(player);
			return table;
		}
		return null;
	}
	
	function sitPlayer(Player player) {
		if (exists table = tableList.find((table) => table.queueSize == 1), table.sitPlayer(player)) {
			updatedPlayers.add(player);
			return table;
		}
		return openTable(player);
	}
	
	function doRemovePlayer(Player player) {
		if (exists table = player.table) {
			updatedPlayers.add(player);
			table.removePlayer(player.id);
		}
		if (player.leaveRoom(id)) {
			playerMap.remove(player.id);
			oldPlayers.add(player);
			return player;
		} else {
			return null;
		}
	}
	
	shared Integer removeInactivePlayers(Instant timeoutTime) {
		variable value result = 0;
		for (player in playerMap.items.clone()) {
			if (!player.isPlaying() && player.isInactiveSince(timeoutTime)) {
				doRemovePlayer(player);
				result++;
			}
		}
		return result;
	}
	
	shared Player? definePlayer(PlayerInfo info) {
		if (exists player = findPlayer(PlayerId(info.id))) {
			return player;
		} else if (playerMap.size >= playerCountLimit) {
			return null;
		} else {
			value player = Player(info, this);
			playerMap.put(player.id, player);
			newPlayers.add(player);
			_createdPlayerCount++;
			return player;
		}
	}
	
	shared Player? removePlayer(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
		 	return doRemovePlayer(player);
		} else {
			return null;
		}
	}
	
	shared Player? registerPlayerChange(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			updatedPlayers.add(player);
			return player;
		} else {
			return null;
		}
	}
	
	shared Table? findMatchTable(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			if (exists table = player.table, table.isInRoom(id)) {
				if (player.isPlaying()) {
					return table;
				} else if (table.removePlayer(playerId) exists) {
					return sitPlayer(player);
				} else {
					return null;
				}
			} else if (!player.table exists) {
				return sitPlayer(player);
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	shared Table? findEmptyTable(PlayerId playerId) {
		if (exists player = findPlayer(playerId)) {
			if (exists table = player.table, table.isInRoom(id)) {
				if (player.isPlaying()) {
					return null;
				} else if (table.queueSize == 1) {
					return table;
				} else if (table.removePlayer(playerId) exists) {
					return openTable(player);
				} else {
					return null;
				}
			} else if (!player.table exists) {
				return openTable(player);
			} else {
				return null;
			}
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
	
	shared Boolean addMatch(Match match) {
		if (matchMap.defines(match.id)) {
			return false;
		} else {
			_createdMatchCount++;
			matchMap.put(match.id, match);
			return true;
		}
	}
	
	shared Boolean removeMatch(MatchId matchId) {
		return matchMap.remove(matchId) exists;
	}
	
	shared Match? findMatch(MatchId matchId) {
		return matchMap[matchId];
	}
	
	shared MatchState? findMatchState(TableId tableId, PlayerId playerId) {
		if (exists player = findPlayer(playerId), exists match = player.findRecentMatch(tableId)) {
			return match.state;
		} else {
			return null;
		}
	}
	
	shared Player? findPlayer(PlayerId playerId) {
		if (exists player = playerMap[playerId], player.isInRoom(id)) {
			return player;
		} else {
			return null;
		}
	}
	
	shared Integer playerListDeltaSize => newPlayers.size + oldPlayers.size + updatedPlayers.size; 
	
	shared PlayerListMessage? createPlayerListDelta() {
		if (newPlayers.empty && oldPlayers.empty && updatedPlayers.empty) {
			return null;
		}
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