import backgammon.server.room {
	Player,
	Table,
	Match
}
import backgammon.shared {
	CreatedGameMessage,
	AcceptedMatchMessage,
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

class MatchTest() {
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), null);
	
	
	value messageList = ArrayList<TableMessage>();
	value match = Match(makePlayer("player1"), makePlayer("player2"), Table(0, RoomId("room"), messageList.add));
	
	test
	shared void newMatchIsNotStarted() {
		assert (!match.isStarted);
	}
	
	test
	shared void startGameWithThirdPlayer() {
		value result = match.acceptMatch(makePlayer("player3"));
		assert (!result);
		assert (messageList.count((TableMessage element) => element is AcceptedMatchMessage) == 0);
	}
	
	test
	shared void startGameWithTwoPlayers() {
		value result1 = match.acceptMatch(match.player1);
		assert (result1);
		value result2 = match.acceptMatch(match.player2);
		assert (result2);
		assert (messageList.count((TableMessage element) => element is AcceptedMatchMessage) == 2);
		assert (messageList.count((TableMessage element) => element is CreatedGameMessage) == 1);
	}
	
	test
	shared void startGameWithOnlyOnePlayer() {
		value result = match.acceptMatch(match.player1);
		assert (result);
		assert (messageList.count((TableMessage element) => element is AcceptedMatchMessage) == 1);
	}
}