import backgammon.shared {
	RoomId,
	PlayerId,
	OutboundTableMessage,
	PlayerInfo,
	OutboundMatchMessage
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
	
	value tableList = ArrayList<Table>(tableCount);
	
	for (i in 0:tableCount) {
		value table = Table(i, id, messageBroadcaster);
		tableList.add(table);
	}
	
	shared List<Table> tables => tableList;
	
	shared Player createPlayer(PlayerInfo info) {
		value player = Player(info, this);
		value oldPlayer = playerMap.put(player.id, player);
		if (exists oldPlayer) {
			oldPlayer.leaveRoom();
		}
		return player;
	}
	
	shared Map<PlayerId, Player> players => playerMap;
	
	shared Boolean sitPlayer(Player player) {
		if (!player.isInRoom(id)) {
			return false;
		} else if (exists table = tableList.find((Table element) => element.queueSize == 1)) {
			return player.joinTable(table.index);
		} else if (exists table = tableList.find((Table element) => element.queueSize == 0)) {
			return player.joinTable(table.index);
		}
		return false;
	}
	
	shared Boolean removePlayer(Player player) {
		return playerMap.removeEntry(player.id, player);
	}
	
	shared Integer removeInactivePlayers(Instant timeoutTime) {
		variable value result = 0;
		for (player in playerMap.items.clone()) {
			if (!player.isPlaying() && player.isInactiveSince(timeoutTime)) {
				player.leaveRoom();
				result++;
			}
		}
		return result;
	}
}
