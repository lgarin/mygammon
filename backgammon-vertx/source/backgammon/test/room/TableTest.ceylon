import backgammon.server.room {
	Player,
	Table
}
import backgammon.shared {
	CreatedMatchMessage,
	PlayerInfo,
	TableMessage,
	LeftTableMessage,
	JoinedTableMessage,
	RoomId,
	PlayerStatistic
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class TableTest() {

	value messageList = ArrayList<TableMessage>();
	value matchBet = 10;
	value matchPot = 18;
	value table = Table(1, RoomId("room"), matchBet, messageList.add);
	
	function makePlayer(String id, Integer initialBalance = matchBet) => Player(PlayerInfo(id, id), PlayerStatistic(initialBalance));
	
	test
	shared void newTableIsFree() {
		assert (table.queueSize == 0);
		assert (table.queueState == []);
		assert (!table.newMatch(matchPot) exists);
		assert (!table.matchState exists);
	}
	
	test
	shared void sitSinglePlayer() {
		value result = table.sitPlayer(makePlayer("player1"));
		assert (result);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 1);
		assert (table.queueSize == 1);
		assert (!table.newMatch(matchPot) exists);
	}
	
	test
	shared void sitPlayerWithUnsufficiantBalance() {
		value result = table.sitPlayer(makePlayer("player1", matchBet - 1));
		assert (!result);
	}
	
	test
	shared void sitSamePlayerTwice() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.sitPlayer(player);
		assert (!result);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 1);
		assert (table.queueSize == 1);
		assert (!table.newMatch(matchPot) exists);
	}
	
	test
	shared void sitTwoPlayers() {
		value result1 = table.sitPlayer(makePlayer("player1"));
		assert (result1);
		value result2 = table.sitPlayer(makePlayer("player2"));
		assert (result2);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 2);
		assert (table.queueSize == 2);
		assert (table.newMatch(matchPot) exists);
		assert (messageList.count((TableMessage element) => element is CreatedMatchMessage) == 1);
		assert (exists state = table.matchState, !state.gameStarted && !state.gameEnded);
	}
	
	test
	shared void queuePlayer() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		
		value result = table.sitPlayer(makePlayer("player3"));
		assert (result);
		assert (table.queueSize == 3);
		assert (messageList.count((TableMessage element) => element is JoinedTableMessage) == 3);
	}
	
	test
	shared void createNewMatch() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		value match = table.newMatch(matchPot);
		assert (exists match);
		assert (messageList.count((TableMessage element) => element is CreatedMatchMessage) == 1);
		assert (exists state = table.matchState, !state.gameStarted && !state.gameEnded);
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
		assert (table.queueSize == 1);
		value result = table.removePlayer(player);
		assert (result);
		assert (messageList.count((TableMessage element) => element is LeftTableMessage) == 1);
		assert (table.queueSize == 0);
	}
	
	test
	shared void removePlayerInMatch() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		value match = table.newMatch(matchPot);
		assert (exists match);
		value result = table.removePlayer(match.player1);
		assert (result);
	}
}