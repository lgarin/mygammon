import backgammon.server.room {
	Room,
	Player
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
	shared void isNotInRoomAfterLeaving() {
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
		value id = player.matchId;
		assert (!exists id);
	}
	
	test
	shared void joinChoosenTable() {
		value table = room.tables.first;
		assert (exists table);
		value result = player.joinTable(table);
		assert (result);
		assert (exists tableIndex = player.tableIndex);
		assert (tableIndex == 0);
		assert (messageList.count((RoomMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void leaveTableWithoutMatch() {
		value table = room.tables.first;
		assert (exists table);
		player.joinTable(table);
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void leaveTableWithMatch() {
		value table = room.tables.first;
		assert (exists table);
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value result = player.leaveTable();
		assert (!result);
	}
	
	test
	shared void notPlayingWithoutTable() {
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithoutMatch() {
		value table = room.tables.first;
		assert (exists table);
		table.sitPlayer(player);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void notPlayingWithMatch() {
		value table = room.tables.first;
		assert (exists table);
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value result = player.isPlaying();
		assert (!result);
	}
	
	test
	shared void playingWithGame() {
		value table = room.tables.first;
		assert (exists table);
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value matchId = table.matchId;
		assert (exists matchId);
		player.acceptMatch(matchId);
		opponent.acceptMatch(matchId);
		value result = player.isPlaying();
		assert (result);
	}

	test
	shared void acceptMatch() {
		value table = room.tables.first;
		assert (exists table);
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value matchId = table.matchId;
		assert (exists matchId);
		value result = player.acceptMatch(matchId);
		assert (result);
	}
	
	test
	shared void joinStartedMatch() {
		value table = room.tables.first;
		assert (exists table);
		value other = makePlayer("other");
		table.sitPlayer(other);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value matchId = table.matchId;
		assert (exists matchId);
		other.acceptMatch(matchId);
		opponent.acceptMatch(matchId);
		value result = player.acceptMatch(matchId);
		assert (!result);
	}
}