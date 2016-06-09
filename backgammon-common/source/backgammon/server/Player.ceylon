import ceylon.collection {
	ArrayList
}

import ceylon.test {
	test
}

import ceylon.time {
	Instant,
	now
}

shared interface Player {

	shared formal String id;
	
	shared formal String? roomId;
	shared formal Integer? tableIndex;

	shared formal Boolean joinTable(Integer tableIndex);
	shared formal Boolean leaveRoom();
	shared formal Boolean leaveTable();
	shared formal Boolean startGame();
	shared formal Boolean leaveMatch();
	shared formal Boolean findMatchTable();
}

class PlayerImpl(shared actual String id, variable RoomImpl? room = null) satisfies Player {
	variable TableImpl? table = null;
	variable MatchImpl? match = null;
	variable Instant lastActivity = now();
	
	shared actual String? roomId => room?.id;
	shared actual Integer? tableIndex => table?.index;
	
	shared Boolean isInRoom(String roomId) {
		return room?.id?.equals(roomId) else false;
	}
	
	shared actual Boolean leaveRoom() {
		leaveTable();
		if (exists currentRoom = room) {
			currentRoom.removePlayer(this);
			room = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared actual Boolean leaveTable() {
		leaveMatch();
		
		if (exists currentTable = table) {
			currentTable.removePlayer(this);
			table = null;
			world.publish(LeaftTableMessage(this, currentTable));
			return true;
		} else {
			return false;
		}
	}
	
	shared actual Boolean findMatchTable() {
		if (exists currentRoom = room) {
			return currentRoom.sitPlayer(this);
		} else {
			return false;
		}
	}
	
	Boolean doJoinTable(TableImpl currentTable) {
		leaveTable();
		
		table = currentTable;
		lastActivity = now();
		world.publish(JoinedTableMessage(this, currentTable));
		value seated = currentTable.sitPlayer(this);
		if (seated && match is Null) {
			world.publish(WaitingOpponentMessage(this, currentTable));
		}
		return true;
	}
	
	shared actual Boolean joinTable(Integer tableIndex) {
		if (exists currentRoom = room) {
			value table = currentRoom.tables[tableIndex];
			if (exists currentTable = table) {
				return doJoinTable(currentTable);
			}
		}
		return false;
	}
	
	shared actual Boolean startGame() {
		lastActivity = now();
		return match?.startGame(this) else false;
	}
	
	shared actual Boolean leaveMatch() {
		if (exists currentMatch = match) {
			currentMatch.end(this);
			match = null;
			return true;
		}
		return false;
	}
	
	shared Boolean joinMatch(MatchImpl currentMatch) {
		if (currentMatch.game exists) {
			return false;
		}
		
		leaveMatch();
		
		match = currentMatch;
		lastActivity = now();
		world.publish(JoiningMatchMessage(this, currentMatch));
		return true;
	}
	
	shared Boolean isWaitingSeat() => table exists && match is Null;
	
	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
}

class PlayerTest() {
	
	value messageList = ArrayList<ApplicationMessage>();
	world.messageListener = messageList.add;
	
	value room = RoomImpl("room", 1);
	value player = PlayerImpl("player", room);
	
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
		assert (!result);
		assert (messageList.count((ApplicationMessage element) => element is JoinedTableMessage) == 0);
	}
	
	test
	shared void findMatchTableWithoutRoom() {
		player.leaveRoom();
		value result = player.findMatchTable();
		assert (!result);
	}
	
	test
	shared void findMatchTableWithOpponent() {
		value opponent = PlayerImpl("opponent", room);
		opponent.findMatchTable();
		value result = player.findMatchTable();
		assert (result);
		assert (messageList.count((ApplicationMessage element) => element is JoinedTableMessage) == 2);
	}
	
	test
	shared void joinChoosenTable() {
		value result = player.joinTable(0);
		assert (result);
		assert (exists tableIndex = player.tableIndex);
		assert (tableIndex == 0);
		assert (messageList.count((ApplicationMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void leaveTableWithoutMatch() {
		player.joinTable(0);
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void leaveTableWithMatch() {
		value opponent = PlayerImpl("opponent", room);
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void waitingSeatWithoutTable() {
		value result = player.isWaitingSeat();
		assert (!result);
	}
	
	test
	shared void waitingSeatWithoutMatch() {
		player.joinTable(0);
		value result = player.isWaitingSeat();
		assert (result);
	}
	
	test
	shared void waitingSeatWithMatch() {
		value opponent = PlayerImpl("opponent", room);
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.isWaitingSeat();
		assert (!result);
	}
	
	test
	shared void joinMatch() {
		value opponent = PlayerImpl("opponent", room);
		value table = TableImpl(0, room.id);
		value match = MatchImpl(player, opponent, table);
		value result = player.joinMatch(match);
		assert (result);
	}
	
	test
	shared void joinStartedMatch() {
		value opponent = PlayerImpl("opponent", room);
		value table = TableImpl(0, room.id);
		value match = MatchImpl(player, opponent, table);
		match.startGame(opponent);
		match.startGame(player);
		value result = player.joinMatch(match);
		assert (!result);
	}
}
