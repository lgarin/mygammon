import backgammon.common {
	WaitingOpponentMessage,
	JoinedTableMessage,
	RoomId,
	PlayerId,
	OutboundTableMessage,
	OutboundMatchMessage,
	RoomMessage,
	PlayerInfo,
	CreatedMatchMessage
}

import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked
}
import ceylon.test {
	test
}
import ceylon.time {
	Instant
}

final class Room(String roomId, shared Integer tableCount, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
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
		for (player in playerMap.items.sequence()) {
			if (!player.isPlaying() && player.isInactiveSince(timeoutTime)) {
				player.leaveRoom();
				result++;
			}
		}
		return result;
	}
}

class RoomTest() {
	value messageList = ArrayList<RoomMessage>();
	value room = Room("test1", 10, messageList.add);
	
	function makePlayerInfo(String id) => PlayerInfo(id, id, null);
	
	test
	shared void newRoomHasNoPlayer() {
		assert (room.players.size == 0);
	}
	
	test
	shared void newRoomHasTenTables() {
		assert (room.tables.size == 10);
	}
	
	test
	shared void newRoomHasOnlyFreeTables() {
		assert (room.tables.every((Table element) => element.free));
	}
	
	test
	shared void createPlayerAddsPlayer() {
		value player = room.createPlayer(makePlayerInfo("player1"));
		assert (room.players.size == 1);
		assert (exists roomId = player.roomId);
		assert (roomId == room.id);
	}
	
	test
	shared void createPlayerTwiceReplaceExisting() {
		value oldPlayer = room.createPlayer(makePlayerInfo("player1"));
		value newPlayer = room.createPlayer(makePlayerInfo("player1"));
		assert (room.players.size == 1);
		assert (oldPlayer.roomId is Null);
		assert (newPlayer.roomId is RoomId);
	}
	
	test
	shared void removeExistingPlayer() {
		value player = room.createPlayer(makePlayerInfo("player1"));
		value result = room.removePlayer(player);
		assert (result);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = room.createPlayer(makePlayerInfo("player1"));
		room.removePlayer(player);
		value result = room.removePlayer(player);
		assert (!result);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.createPlayer(makePlayerInfo("player1"));
		value result = room.sitPlayer(player);
		assert (result);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
		assert (messageList.count((RoomMessage element) => element is WaitingOpponentMessage) == 1);
		assert (room.tables.count((Table element) => !element.free) == 1);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.createPlayer(makePlayerInfo("player1"));
		value player2 = room.createPlayer(makePlayerInfo("player2"));
		value result1 = room.sitPlayer(player1);
		assert (result1);
		value result2 = room.sitPlayer(player2);
		assert (result2);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((RoomMessage element) => element is WaitingOpponentMessage) == 1);
		assert (messageList.count((RoomMessage element) => element is CreatedMatchMessage) == 1);
		assert (room.tables.count((Table element) => !element.free) == 1);
	}
}