import backgammon.shared {
	RoomId,
	PlayerId,
	OutboundTableMessage,
	PlayerInfo,
	OutboundMatchMessage,
	TableId,
	MatchId
}

import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked
}
import ceylon.time {
	Instant
}

final shared class Room(shared String roomId, shared Integer tableCount, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared RoomId id = RoomId(roomId);
	
	value playerMap = HashMap<PlayerId, Player>(unlinked);
	
	// TODO use table map
	value tableList = ArrayList<Table>(tableCount);
	
	for (i in 0:tableCount) {
		value table = Table(i, id, messageBroadcaster);
		tableList.add(table);
	}
	
	shared Integer playerCount => playerMap.size;
	shared Integer freeTableCount => tableList.count((Table element) => element.queueSize == 0);
	
	function findReadyTable() => tableList.find((Table element) => element.queueSize == 1);
	function findEmptyTable() => tableList.find((Table element) => element.queueSize == 0);
	
	function sitPlayer(Player player) {
		if (exists table = findReadyTable(), table.sitPlayer(player)) {
			return table;
		} else if (exists table = findEmptyTable(), table.sitPlayer(player)) {
			return table;
		} else {
			return null;
		}
	}
	
	function doRemovePlayer(Player player) {
		if (exists table = player.table, player.leaveTable(table.id)) {
			table.removePlayer(player.id);
		}
		if (player.leaveRoom(id)) {
			playerMap.remove(player.id);
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
	
	shared Player? addPlayer(PlayerInfo info) {
		if (playerMap.defines(PlayerId(info.id))) {
			return null;
		} else {
			value player = Player(info, this);
			playerMap.put(player.id, player);
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
	
	shared Table? findTable(TableId tableId) {
		if (tableId.roomId == roomId) {
			return tableList[tableId.table];
		} else {
			return null;
		}
	}
	
	shared Match? findMatch(MatchId matchId) {
		return findTable(matchId.tableId)?.findMatch(matchId);
	}
	
	shared Player? findPlayer(PlayerId playerId) {
		if (exists player = playerMap[playerId], player.isInRoom(id)) {
			return player;
		} else {
			return null;
		}
	}
}