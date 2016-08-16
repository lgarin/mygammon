import backgammon.server.room {
	Room,
	Player
}
import backgammon.shared {
	RoomMessage,
	PlayerInfo,
	TableId
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
	value table = room.findTable(TableId(room.roomId, 0));
	assert (exists table);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), room);
	
	value player = makePlayer("player");
	
	test
	shared void newPlayerIsInRoom() {
		value result = player.isInRoom(room.id);
		assert (result);
	}
	
	test
	shared void leaveRoom() {
		value result = player.leaveRoom(room.id);
		assert (result);
	}
	
	test
	shared void isNotInRoomAfterLeaving() {
		player.leaveRoom(room.id);
		value result = player.isInRoom(room.id);
		assert (!result);
	}
	
	test
	shared void newPlayerHasNoTable() {
		assert (!player.table exists);
	}
	
	test
	shared void newPlayerHasNoMatch() {
		assert (!player.match exists);
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
		value match = table.match;
		assert (exists match);
		match.markReady(player.id);
		match.markReady(opponent.id);
		value result = player.isPlaying();
		assert (result);
	}

	test
	shared void acceptMatch() {
		table.sitPlayer(player);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.match;
		assert (exists match);
		value result = player.acceptMatch(match.id);
		assert (result);
	}
	
	test
	shared void joinStartedMatch() {
		value other = makePlayer("other");
		table.sitPlayer(other);
		value opponent = makePlayer("opponent");
		table.sitPlayer(opponent);
		value match = table.match;
		assert (exists match);
		match.markReady(other.id);
		match.markReady(opponent.id);
		value result = player.acceptMatch(match.id);
		assert (!result);
	}
}