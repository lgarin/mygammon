import backgammon.server.room {
	Player,
	Table,
	Match
}
import backgammon.shared {
	RoomMessage,
	PlayerInfo,
	RoomId,
	PlayerStatistic
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
import ceylon.time {
	now
}

class PlayerTest() {
	
	value matchBet = 10;
	value matchPot = 18;
	value initialBalance = 1000;
	value messageList = ArrayList<RoomMessage>();
	
	value table = Table(1, RoomId("room"), matchBet, messageList.add);
	
	function makePlayer(String id, Integer balance = initialBalance) => Player(PlayerInfo(id, id, balance));
	
	value player = makePlayer("player");
	
	test
	shared void checkNewPlayer() {
		assert (!player.table exists);
		assert (!player.match exists);
		assert (!player.isPlaying());
		assert (player.isInactiveSince(now()));
		assert (player.statistic == PlayerStatistic(initialBalance, 0, 0, 0));
	}
	
	test
	shared void markPlayerActiveUpdatesActivity() {
		player.markActive();
		assert (!player.isInactiveSince(now()));
	}

	test
	shared void joinChoosenTable() {
		value result = player.joinTable(table);
		assert (result);
		assert (player.isAtTable(table.id));
	}
	
	test
	shared void leaveTableWithoutMatch() {
		player.joinTable(table);
		value result = player.leaveTable(table.id);
		assert (result);
		assert (!player.isAtTable(table.id));
	}
	
	function startMatch() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.newMatch(matchPot);
		assert (exists match);
		return match;
	}
	
	test
	shared void leaveTableWithMatch() {
		startMatch();
		value result = player.leaveTable(table.id);
		assert (result);
		assert (!player.isAtTable(table.id));
	}
	
	function startGame() {
		value match = startMatch();
		match.markReady(match.player1.id);
		match.markReady(match.player2.id);
		return match;
	}
	
	test
	shared void leaveTableWithGame() {
		startGame();
		value result = player.leaveTable(table.id);
		assert (!result);
		assert (player.isAtTable(table.id));
	}
	
	test
	shared void notPlayingWithoutTable() {
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithoutMatch() {
		player.joinTable(table);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithUnstartedGame() {
		startMatch();
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void playingWithGame() {
		startGame();
		value result = player.isPlaying();
		assert (result);
	}
	
	test
	shared void joinNewMatch() {
		value match = startMatch();
		assert (player.isInMatch(match.id));
		assert (player.statistic == PlayerStatistic(initialBalance, 0, 0, 0));
	}
	
	test
	shared void cannotJoinMatchWithUnsufficiantBalance() {
		value player = makePlayer("player0", table.matchBet - 1);
		player.joinTable(table);
		value match = Match(player, makePlayer("other"), table, matchPot, messageList.add);
		value result = player.joinMatch(match);
		assert (!result);
	}
	
	test
	shared void placeBetDecreasesBalance() {
		player.placeBet(100);
		assert (player.statistic == PlayerStatistic(initialBalance - 100, 0, 0, 0));
	}
	
	test
	shared void increaseWonGame() {
		player.increaseWonGame(100, 10);
		assert (player.statistic == PlayerStatistic(initialBalance + 10, 0, 1, 100));
	}
	
	test
	shared void increasePlayedGame() {
		player.increasePlayedGame();
		assert (player.statistic == PlayerStatistic(initialBalance, 1, 0, 0));
	}
}