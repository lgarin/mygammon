import backgammon.server.room {
	Room,
	Player
}
import backgammon.shared {
	JoinedTableMessage,
	CreatedMatchMessage,
	RoomMessage,
	PlayerInfo
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class RoomTest() {
	value messageList = ArrayList<RoomMessage>();
	value room = Room("test1", 10, 10, messageList.add);
	
	function makePlayerInfo(String id) => PlayerInfo(id, id);
	
	test
	shared void newRoomHasNoPlayer() {
		assert (room.playerCount == 0);
	}
	
	test
	shared void newRoomHasTenTables() {
		assert (room.tableCountLimit == 10);
	}
	
	test
	shared void newRoomHasOnlyFreeTables() {
		assert (room.freeTableCount == 10);
	}
	
	test
	shared void addNewPlayer() {
		value result = room.definePlayer(makePlayerInfo("player1"));
		assert (result exists);
		assert (room.playerCount == 1);
	}
	
	test
	shared void addSamePlayerIdTwice() {
		room.definePlayer(makePlayerInfo("player1"));
		value result = room.definePlayer(makePlayerInfo("player1"));
		assert (result exists);
		assert (room.playerCount == 1);
	}
	
	test
	shared void removeExistingPlayer() {
		value player = room.definePlayer(makePlayerInfo("player1"));
		assert (exists player);
		value result = room.removePlayer(player);
		assert (result);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = Player(makePlayerInfo("player1"));
		value result = room.removePlayer(player);
		assert (!result);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.definePlayer(makePlayerInfo("player1"));
		assert (exists player);
		value result = room.findMatchTable(player);
		assert (result exists);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.definePlayer(makePlayerInfo("player1"));
		assert (exists player1);
		value player2 = room.definePlayer(makePlayerInfo("player2"));
		assert (exists player2);
		value result1 = room.findMatchTable(player1);
		assert (result1 exists);
		value result2 = room.findMatchTable(player2);
		assert (result2 exists);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((RoomMessage element) => element is CreatedMatchMessage) == 1);
	}
}