import ceylon.collection {
	ArrayList,
	HashSet,
	HashMap,
	unlinked,
	linked
}
import ceylon.test {

	test
}
import ceylon.time {

	now,
	Duration
}

shared interface Room {
	shared formal String id;
	
	shared formal Player createPlayer(String id);
	
	shared formal Integer removeInactivePlayers(Duration timeout);
	
	shared formal Map<String, Player> players;
	
	shared formal List<Table> tables;
}

class RoomImpl(shared actual String id, shared Integer tableCount) satisfies Room {
	
	value playerMap = HashMap<String, PlayerImpl>(unlinked);
	
	value playerQueue = HashSet<PlayerImpl>(linked);
	
	value tableList = ArrayList<TableImpl>(tableCount);
	
	for (i in 0:tableCount) {
		value table = TableImpl(i);
		tableList.add(table);
	}
	
	shared actual List<TableImpl> tables => tableList;
	
	shared actual PlayerImpl createPlayer(String id) {
		value player = PlayerImpl(id, this);
		value oldPlayer = playerMap.put(id, player);
		if (exists oldPlayer) {
			oldPlayer.leaveRoom();
		}
		return player;
	}
	
	shared actual Map<String, Player> players => playerMap;
	
	shared Boolean sitPlayer(PlayerImpl player) {
		if (!player.isInRoom(id)) {
			return false;
		} else if (exists opponent = playerQueue.first) {
			value table = tableList.find((TableImpl element) => element.queueSize == 0);
			if (exists table) {
				playerQueue.remove(opponent);
				return opponent.joinTable(table.index) && player.joinTable(table.index);
			}
		} else {
			value table = tableList.find((TableImpl element) => element.queueSize == 1);
			if (exists table) {
				return player.joinTable(table.index);
			}
		}
		
		playerQueue.add(player);
		return false;
	}
	
	shared Boolean removePlayer(PlayerImpl player) {
		playerQueue.remove(player);
		return playerMap.removeEntry(player.id, player);
	}
	
	shared actual Integer removeInactivePlayers(Duration timeout) {
		value timeoutTime = now().minus(timeout);
		variable value result = 0;
		for (player in playerMap.items) {
			if (!playerQueue.contains(player) && !player.isWaitingSeat() && player.isInactiveSince(timeoutTime)) {
				player.leaveRoom();
				result++;
			}
		}
		return result;
	}
}

class RoomTest() {
	value room = RoomImpl("test1", 10);
	
	value messageList = ArrayList<ApplicationMessage>();
	world.messageListener = messageList.add;
	
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
		value player = room.createPlayer("player1");
		assert (room.players.size == 1);
		assert (exists roomId = player.roomId);
		assert (roomId == room.id);
	}
	
	test
	shared void createPlayerTwiceReplaceExisting() {
		value oldPlayer = room.createPlayer("player1");
		value newPlayer = room.createPlayer("player1");
		assert (room.players.size == 1);
		assert (oldPlayer.roomId is Null);
		assert (newPlayer.roomId is String);
	}
	
	test
	shared void removeExistingPlayer() {
		value player = room.createPlayer("player1");
		value result = room.removePlayer(player);
		assert (result);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = room.createPlayer("player1");
		room.removePlayer(player);
		value result = room.removePlayer(player);
		assert (!result);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.createPlayer("player1");
		value result = room.sitPlayer(player);
		assert (!result);
		assert (messageList.count((ApplicationMessage element) => element is WaitingOpponentMessage) == 0);
		assert (room.tables.count((Table element) => !element.free) == 0);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.createPlayer("player1");
		value player2 = room.createPlayer("player2");
		value result1 = room.sitPlayer(player1);
		assert (!result1);
		value result2 = room.sitPlayer(player2);
		assert (result2);
		assert (messageList.count((ApplicationMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((ApplicationMessage element) => element is WaitingOpponentMessage) == 1);
		assert (messageList.count((ApplicationMessage element) => element is JoiningMatchMessage) == 2);
		assert (room.tables.count((Table element) => !element.free) == 1);
	}
}