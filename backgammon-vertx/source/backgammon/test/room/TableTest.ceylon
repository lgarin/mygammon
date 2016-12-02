import backgammon.server.room {
	Player,
	Room
}
import backgammon.shared {
	CreatedMatchMessage,
	PlayerInfo,
	TableMessage,
	LeftTableMessage,
	JoinedTableMessage,
	TableId
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class TableTest() {

	value messageList = ArrayList<TableMessage>();
	value room = Room("test", 1, 10, messageList.add);
	value table = room.findTable(TableId(room.roomId, 1));
	assert (exists table);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id), room);
	
	test
	shared void newTableIsFree() {
		assert (table.queueSize == 0);
	}
	
	test
	shared void sitSinglePlayer() {
		value result = table.sitPlayer(makePlayer("player1"));
		assert (result);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void sitSamePlayerTwice() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.sitPlayer(player);
		assert (!result);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void sitTwoPlayers() {
		value result1 = table.sitPlayer(makePlayer("player1"));
		assert (result1);
		value result2 = table.sitPlayer(makePlayer("player2"));
		assert (result2);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((TableMessage element) => element is CreatedMatchMessage) == 1);
	}
	
	test
	shared void queuePlayer() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		
		value result = table.sitPlayer(makePlayer("player3"));
		assert (result);
		assert (table.queueSize == 3);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 3);
		assert (messageList.count((TableMessage element) => element is CreatedMatchMessage) == 1);
	}
	
	test
	shared void removeUnknownPlayer() {
		value result = table.removePlayer(makePlayer("player1"));
		assert (!result);
		assert (messageList.empty);
		assert (messageList.count((TableMessage element) => element is LeftTableMessage) == 0);
	}
	
	test
	shared void removeKnownPlayer() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.removePlayer(player);
		assert (result);
		assert (messageList.count((TableMessage element) => element is LeftTableMessage) == 1);
	}
}