import backgammon.server.room {
	Player,
	Table
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
	
	value messageList = ArrayList<RoomMessage>();
	
	value table = Table(1, RoomId("room"), messageList.add);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id));
	
	value player = makePlayer("player");
	
	test
	shared void checkNewPlayer() {
		assert (!player.table exists);
		assert (!player.match exists);
		assert (!player.isPlaying());
		assert (player.isInactiveSince(now()));
		assert (player.statistic == PlayerStatistic(0, 0, 0));
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
	}
	
	test
	shared void leaveTableWithMatch() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value result = player.leaveTable(table.id);
		assert (result);
	}
	
	test
	shared void notPlayingWithoutTable() {
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithoutMatch() {
		table.sitPlayer(player);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithUnstartedMatch() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void playingWithGame() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.newMatch();
		assert (exists match);
		match.markReady(player.id);
		match.markReady(opponent.id);
		value result = player.isPlaying();
		assert (result);
	}

	test
	shared void joinNewMatch() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.newMatch();
		assert (exists match);
		value result = player.canAcceptMatch(match.id);
		assert (result);
		assert (player.statistic == PlayerStatistic(0, 0, 0));
	}
	
	test
	shared void joinStartedMatch() {
		value other = makePlayer("other");
		table.sitPlayer(other);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.newMatch();
		assert (exists match);
		match.markReady(other.id);
		match.markReady(opponent.id);
		value result = player.canAcceptMatch(match.id);
		assert (!result);
	}
	
	test
	shared void increaseScore() {
		player.increaseScore(100);
		assert (player.statistic == PlayerStatistic(0, 1, 100));
	}
	
	test
	shared void increasePlayedGame() {
		player.increasePlayedGame();
		assert (player.statistic == PlayerStatistic(1, 0, 0));
	}
}