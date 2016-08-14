import backgammon.shared {
	RoomId,
	PlayerId,
	OutboundTableMessage,
	PlayerInfo,
	OutboundMatchMessage,
	TableId
}

import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked
}
import ceylon.time {
	Instant
}

final shared class Room(String roomId, shared Integer tableCount, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared RoomId id = RoomId(roomId);
	
	value playerMap = HashMap<PlayerId, Player>(unlinked);
	
	// TODO use table map
	value tableList = ArrayList<Table>(tableCount);
	
	for (i in 0:tableCount) {
		value table = Table(i, id, messageBroadcaster);
		tableList.add(table);
	}
	
	shared List<Table> tables => tableList;
	
	shared Map<PlayerId, Player> players => playerMap;
	
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
	
	shared Integer removeInactivePlayers(Instant timeoutTime) {
		variable value result = 0;
		for (player in playerMap.items.clone()) {
			if (!player.isPlaying() && player.isInactiveSince(timeoutTime)) {
				removePlayer(player.id);
				result++;
			}
		}
		return result;
	}
	
	shared Player? addPlayer(PlayerInfo info) {
		if (exists player = playerMap[PlayerId(info.id)]) {
			return null;
		} else {
			value player = Player(info, this);
			playerMap.put(player.id, player);
			return player;
		}
	}
	
	shared Player? removePlayer(PlayerId playerId) {
		if (exists player = playerMap[playerId]) {
			// TODO ugly
			if (exists index = player.tableIndex) {
				tableList[index]?.removePlayer(playerId);
			}
			if (player.leaveRoom()) {
				playerMap.remove(player.id);
				return player;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	shared Table? findMatchTable(PlayerId playerId) {
		if (exists player = playerMap[playerId]) {
			// TODO ugly
			if (player.isPlaying(), exists index = player.tableIndex) {
				return tableList[index];
			} else if (!player.tableIndex exists) {
				return sitPlayer(player);
			} else if (exists index = player.tableIndex, exists table = tableList[index], table.removePlayer(playerId) exists) {
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
}
