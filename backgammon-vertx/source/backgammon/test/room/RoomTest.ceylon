import backgammon.server.room {
	Room
}
import backgammon.shared {
	JoinedTableMessage,
	CreatedMatchMessage,
	RoomMessage,
	PlayerInfo,
	PlayerId
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
	
	function makePlayerInfo(String id) => PlayerInfo(id, id, null);
	
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
		value player = makePlayerInfo("player1");
		room.definePlayer(player);
		value result = room.removePlayer(PlayerId(player.id));
		assert (result exists);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = makePlayerInfo("player1");
		value result = room.removePlayer(PlayerId(player.id));
		assert (!result exists);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.definePlayer(makePlayerInfo("player1"));
		assert (exists player);
		value result = room.findMatchTable(player.id);
		assert (result exists);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.definePlayer(makePlayerInfo("player1"));
		assert (exists player1);
		value player2 = room.definePlayer(makePlayerInfo("player2"));
		assert (exists player2);
		value result1 = room.findMatchTable(player1.id);
		assert (result1 exists);
		value result2 = room.findMatchTable(player2.id);
		assert (result2 exists);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((RoomMessage element) => element is CreatedMatchMessage) == 1);
	}
}