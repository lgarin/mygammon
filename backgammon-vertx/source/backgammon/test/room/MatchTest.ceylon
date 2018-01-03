import backgammon.server.room {
	Table,
	Player
}
import backgammon.shared {
	RoomMessage,
	RoomId,
	PlayerInfo,
	PlayerStatistic
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
import ceylon.time {

	Instant
}

class MatchTest() {
	
	function makePlayer(String id) => Player(PlayerInfo(id, id), PlayerStatistic(100));
	
	value messageList = ArrayList<RoomMessage>();
	
	value timestamp = Instant(0);
	value matchBet = 10;
	value matchPot = 18;
	value table = Table(1, RoomId("room"), matchBet, messageList.add);
	value player1 = makePlayer("player1");
	table.sitPlayer(player1);
	value player2 = makePlayer("player2");
	table.sitPlayer(player2);
	value match = table.newMatch(timestamp, matchPot);
	assert (exists match);
	
	test
	shared void initialMatchNotStartedOrEnded() {
		assert (!match.gameStarted);
		assert (!match.gameEnded);
	}
	
	test
	shared void markPlayer1Ready() {
		value result = match.markReady(player1.id);
		assert (result);
	}
	
	test
	shared void markPlayer1ReadyTwice() {
		match.markReady(player1.id);
		value result = match.markReady(player1.id);
		assert (result);
	}
	
	test
	shared void markBothPlayerReady() {
		match.markReady(player1.id);
		match.markReady(player2.id);
		assert (match.gameStarted);
	}
}