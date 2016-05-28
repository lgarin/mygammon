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

shared interface Room {
	shared formal String id;
	
	shared formal Player createPlayer(String id, Anything(PlayerMessage) messageListener);
	
	shared formal Map<String, Player> players;
	
	shared formal {Table*} tables;
}

class RoomImpl(shared actual String id, shared Integer tableCount) satisfies Room {
	
	value playerMap = HashMap<String, PlayerImpl>(unlinked);
	
	value playerQueue = HashSet<PlayerImpl>(linked);
	
	value tableList = ArrayList<TableImpl>(tableCount);
	
	value freeTableQueue = HashSet<TableImpl>(linked);
	
	for (i in 1..tableCount) {
		value table = TableImpl(i - 1);
		tableList.add(table);
		freeTableQueue.add(table);
	}
	
	shared actual {TableImpl*} tables => tableList;
	
	shared actual PlayerImpl createPlayer(String id, Anything(PlayerMessage) messageListener) {
		value player = PlayerImpl(id, messageListener, this);
		playerMap.put(id, player);
		return player;
	}
	
	shared actual Map<String, Player> players => playerMap;
	
	shared Boolean sitPlayer(PlayerImpl player) {
		if (freeTableQueue.empty || playerQueue.empty) {
			playerQueue.add(player);
			return false;
		} else {
			value table = freeTableQueue.first;
			assert (exists table);
			value opponent = playerQueue.first;
			assert (exists opponent);
			freeTableQueue.remove(table);
			playerQueue.remove(opponent);
			opponent.joinTable(table);
			player.joinTable(table);
			return true;
		}
	}
	
	shared Boolean enqueueFreeTable(TableImpl table) {
		if (exists currentTable = tableList[table.index], table === currentTable) {
			if (currentTable.free) {
				return freeTableQueue.add(currentTable);
			}
		}
		return false;
	}
	
	shared Boolean removePlayer(PlayerImpl player) {
		playerQueue.remove(player);
		return playerMap.removeEntry(player.id, player);
	}
}

class RoomTest() {
	value room = RoomImpl("test1", 10);
	
	value messageList = ArrayList<PlayerMessage>();
	
	void enqueueMessage(PlayerMessage message) {
		messageList.add(message);
	}
	
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
		room.createPlayer("player1", enqueueMessage);
		assert (room.players.size == 1);
	}
	
	test
	shared void removeExistingPlayer() {
		value player = room.createPlayer("player1", enqueueMessage);
		value result = room.removePlayer(player);
		assert (result);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = room.createPlayer("player1", enqueueMessage);
		room.removePlayer(player);
		value result = room.removePlayer(player);
		assert (!result);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.createPlayer("player1", enqueueMessage);
		value result = room.sitPlayer(player);
		assert (!result);
		assert (messageList.count((PlayerMessage element) => element is WaitingOpponentMessage) == 0);
		assert (room.tables.count((Table element) => !element.free) == 0);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.createPlayer("player1", enqueueMessage);
		value player2 = room.createPlayer("player1", enqueueMessage);
		value result1 = room.sitPlayer(player1);
		assert (!result1);
		value result2 = room.sitPlayer(player2);
		assert (result2);
		assert (messageList.count((PlayerMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((PlayerMessage element) => element is WaitingOpponentMessage) == 1);
		assert (messageList.count((PlayerMessage element) => element is JoiningGameMessage) == 2);
		assert (room.tables.count((Table element) => !element.free) == 1);
	}
	
	test
	shared void enqueueFreeTableWhichWasFree() {
		value table = room.tables.first;
		assert (exists table);
		value result = room.enqueueFreeTable(table);
		assert (!result);
	}
}