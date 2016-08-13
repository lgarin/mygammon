import backgammon.server.room {
	Table,
	Player
}
import backgammon.shared {
	CreatedMatchMessage,
	RoomId,
	PlayerInfo,
	TableMessage
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class TableTest() {

	value messageList = ArrayList<TableMessage>();
	value table = Table(0, RoomId("room"), messageList.add);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), null);
	
	test
	shared void newTableIsFree() {
		assert (table.free);
	}
	
	test
	shared void sitSinglePlayer() {
		value result = table.sitPlayer(makePlayer("player1"));
		assert (result);
		assert (messageList.empty);
	}
	
	test
	shared void sitSamePlayerTwice() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.sitPlayer(player);
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void sitTwoPlayers() {
		value result1 = table.sitPlayer(makePlayer("player1"));
		assert (result1);
		value result2 = table.sitPlayer(makePlayer("player2"));
		assert (result2);
		assert (messageList.count((TableMessage element) => element is CreatedMatchMessage) == 1);
	}
	
	test
	shared void queuePlayer() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		
		value result = table.sitPlayer(makePlayer("player3"));
		assert (!result);
		assert (table.queueSize == 3);
	}
	
	test
	shared void removeUnknownPlayer() {
		value result = table.removePlayer(makePlayer("player1"));
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void removeKnownPlayer() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.removePlayer(player);
		assert (result);
		assert (messageList.empty);
	}
}