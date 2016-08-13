import backgammon.server.room {
	Room,
	Player,
	Table,
	Match
}
import backgammon.shared {
	JoinedTableMessage,
	RoomMessage,
	PlayerInfo
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class PlayerTest() {
	
	value messageList = ArrayList<RoomMessage>();
	
	value room = Room("room", 1, messageList.add);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), room);
	
	value player = makePlayer("player");
	
	test
	shared void newPlayerIsInRoom() {
		value result = player.isInRoom(room.id);
		assert (result);
	}
	
	test
	shared void leaveRoom() {
		value result = player.leaveRoom();
		assert (result);
	}
	
	test
	shared void isNotInRooAfterLeaving() {
		player.leaveRoom();
		value result = player.isInRoom(room.id);
		assert (!result);
	}
	
	test
	shared void newPlayerHasNoTable() {
		value result = player.leaveTable();
		assert (!result);
	}
	
	test
	shared void newPlayerHasNoMatch() {
		value result = player.leaveMatch();
		assert (!result);
	}
	
	test
	shared void joinMatchTableWithoutOpponent() {
		value result = player.findMatchTable();
		assert (result);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void findMatchTableWithoutRoom() {
		player.leaveRoom();
		value result = player.findMatchTable();
		assert (!result);
	}
	
	test
	shared void findMatchTableWithOpponent() {
		value opponent = makePlayer("opponent");
		opponent.findMatchTable();
		value result = player.findMatchTable();
		assert (result);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 2);
	}
	
	test
	shared void joinChoosenTable() {
		value result = player.joinTable(0);
		assert (result);
		assert (exists tableIndex = player.tableIndex);
		assert (tableIndex == 0);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void leaveTableWithoutMatch() {
		player.joinTable(0);
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void leaveTableWithMatch() {
		value opponent = makePlayer("opponent");
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void notPlayingWithoutTable() {
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithoutMatch() {
		player.joinTable(0);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithMatch() {
		value opponent = makePlayer("opponent");
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void playingWithGame() {
		value opponent = makePlayer("opponent");
		opponent.findMatchTable();
		player.findMatchTable();
		player.acceptMatch();
		opponent.acceptMatch();
		value result = player.isPlaying();
		assert (result);
	}

	test
	shared void joinMatch() {
		value opponent = makePlayer("opponent");
		value table = Table(0, room.id, messageList.add);
		value match = Match(player, opponent, table);
		value result = player.joinMatch(match);
		assert (result);
	}
	
	test
	shared void joinStartedMatch() {
		value opponent = makePlayer("opponent");
		value table = Table(0, room.id, messageList.add);
		value match = Match(player, opponent, table);
		match.acceptMatch(opponent);
		match.acceptMatch(player);
		value result = player.joinMatch(match);
		assert (!result);
	}
}