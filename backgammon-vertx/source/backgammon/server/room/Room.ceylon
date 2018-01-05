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
	Instant,
	Duration
}

final shared class Room(shared String roomId, RoomSize maxSize, shared MatchBet matchBet, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
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
	
	shared Integer createdMatchCount => _createdMatchCount;
	shared Integer matchCount => tableList.count((element) => element.match exists);
	shared Integer maxMatchCount => _maxMatchCount;
	
	shared Integer createdPlayerCount => _createdPlayerCount;
	shared Integer playerCount => playerMap.size;
	shared Integer maxPlayerCount=> _maxPlayerCount;
	shared Integer busyPlayerCount => playerMap.count((element) => element.item.isPlaying());
	
	shared Integer createdTableCount => tableList.size;
	shared Integer busyTableCount => tableList.count((element) => element.queueSize > 0);
	shared Integer maxTableCount => _maxTableCount;
	
	void updateTableCount() {
		_maxTableCount = max([_maxTableCount, busyTableCount]);
	}
	
	void updateMatchCount() {
		_createdMatchCount++;
		_maxMatchCount = max([_maxMatchCount, matchCount]);
	}
	
	shared Boolean createMatch(Table table, Instant timestamp) {
		if (exists match = table.newMatch(timestamp, matchBet.matchPot)) {
			updateMatchCount();
			return true;
		} else {
			return false;
		}
	}

	function openTable(Player player) {
		if (exists table = tableList.find((table) => table.queueSize == 0 && table.sitPlayer(player))) {
			updateTableCount();
			updatedPlayers.add(player);
			return table;
		}
		return null;
	}
	
	function sitPlayer(Player player, Instant timestamp) {
		if (exists table = tableList.find((table) => table.queueSize == 1 && table.sitPlayer(player))) {
			createMatch(table, timestamp);
			updateTableCount();
			updatedPlayers.add(player);
			return table;
		}
		return openTable(player);
	}
	
	shared Boolean removePlayer(Player player, Instant timestamp) {
		if (exists tableId = player.tableId, exists table = findTable(tableId)) {
			updatedPlayers.add(player);
			table.removePlayer(player);
			createMatch(table, timestamp);
		}
		if (playerMap.remove(player.id) exists) {
			oldPlayers.add(player);
			return true;
		} else {
			return false;
		}
	}
	
	shared Integer removeInactivePlayers(Instant currentTime, Duration timeoutPeriod) {
		value timeoutTime = currentTime.minus(timeoutPeriod);
		variable value result = 0;
		for (player in playerMap.items.sequence()) {
			if (player.isInactiveSince(timeoutTime) && removePlayer(player, currentTime)) {
				result++;
			}
		}
		return result;
	}
	
	void updatePlayerCount() {
		_createdPlayerCount++;
		_maxPlayerCount = max([_maxPlayerCount, playerMap.size]);
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
			updatePlayerCount();
			return player;
		}
	}
	
	shared void registerPlayerChange(Player player) {
		if (playerMap.defines(player.id)) {
			updatedPlayers.add(player);
		}
	}
	
	shared Table? findMatchTable(Player player, Instant timestamp) {
		if (exists tableId = player.tableId, exists table = findTable(tableId)) {
			return table;
		} else if (!player.tableId exists) {
			return sitPlayer(player, timestamp);
		} else {
			return null;
		}
	}
	
	shared Table? findEmptyTable(Player player) {
		if (exists tableId = player.tableId, exists table = findTable(tableId)) {
			if (player.isPlaying()) {
				return null;
			} else if (table.queueSize == 1) {
				return table;
			} else if (table.removePlayer(player)) {
				return openTable(player);
			} else {
				return null;
			}
		} else if (!player.tableId exists) {
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

	shared Match? findCurrentMatch(MatchId matchId) {
		return findTable(matchId.tableId)?.match;
	}

	shared Player? findPlayer(PlayerId playerId) =>  playerMap[playerId];
	
	shared Integer playerListDeltaSize => newPlayers.size + oldPlayers.size + updatedPlayers.size; 
	
	shared void clearPlayerListDelta() {
		newPlayers.clear();
		oldPlayers.clear();
		updatedPlayers.clear();
	}
	
	shared PlayerListMessage createPlayerListDelta() {
		updatedPlayers.removeAll(newPlayers);
		updatedPlayers.removeAll(oldPlayers);
		value message = PlayerListMessage(id, [for (element in newPlayers) element.state], [for (element in oldPlayers) element.state], [for (element in updatedPlayers) element.state]);
		clearPlayerListDelta();
		return message;
	}
	
	shared [PlayerState*] createPlayerList() {
		return [for (element in playerMap.items) element.state];
	}
	
	shared Set<MatchId> listRecentMatches() {
		value result = HashSet<MatchId>();
		result.addAll {for (table in tableList) if (exists match = table.match) match.id};
		result.addAll {for (player in playerMap.items) if (exists match = player.previousMatch) match.id}; 
		return result;
	}
	
}