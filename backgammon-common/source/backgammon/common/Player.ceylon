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

class PlayerImpl(shared actual String id, shared Anything(PlayerMessage) messageListener, variable RoomImpl? room = null) satisfies Player {
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
			messageListener(LeaftTableMessage(this, currentTable));
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
		messageListener(JoinedTableMessage(this, currentTable));
		value seated = currentTable.sitPlayer(this);
		if (seated && match is Null) {
			messageListener(WaitingOpponentMessage(this, currentTable));
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
		/*
		if (exists currentMatch = match) {
			if (currentMatch.markReady(this)) {
				messageListener(StartGameMessage(this, currentMatch));
				return true;
			}
		}
		 */
		return false;
	}
	
	shared actual Boolean leaveMatch() {
		
		if (exists currentMatch = match) {
			currentMatch.removePlayer(this);
			return true;
		} else {
			return false;
		}
	}
	
	shared void joinMatch(MatchImpl currentMatch) {
		leaveMatch();
		
		match = currentMatch;
		lastActivity = now();
		messageListener(JoiningMatchMessage(this, currentMatch));
	}
	
	shared Boolean isWaitingSeat() => table exists && match is Null;
	
	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
}

class PlayerTest() {
	
	value messageList = ArrayList<PlayerMessage>();
	
	void enqueueMessage(PlayerMessage message) {
		messageList.add(message);
	}
	
	value room = RoomImpl("room", 1);
	value player = PlayerImpl("player", enqueueMessage, room);
	
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
		assert (messageList.count((PlayerMessage element) => element is JoinedTableMessage) == 0);
	}
	
	test
	shared void findMatchTableWithoutRoom() {
		player.leaveRoom();
		value result = player.findMatchTable();
		assert (!result);
	}
	
	test
	shared void findMatchTableWithOpponent() {
		value opponent = PlayerImpl("opponent", enqueueMessage, room);
		opponent.findMatchTable();
		value result = player.findMatchTable();
		assert (result);
		assert (messageList.count((PlayerMessage element) => element is JoinedTableMessage) == 2);
	}
	
	test
	shared void joinChoosenTable() {
		value result = player.joinTable(0);
		assert (result);
		assert (exists tableIndex = player.tableIndex);
		assert (tableIndex == 0);
		assert (messageList.count((PlayerMessage element) => element is JoinedTableMessage) == 1);
	}
	
	test
	shared void leaveTableWithoutMatch() {
		player.joinTable(0);
		value result = player.leaveTable();
		assert (result);
	}
	
	test
	shared void leaveTableWithMatch() {
		value opponent = PlayerImpl("opponent", enqueueMessage, room);
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
		value opponent = PlayerImpl("opponent", enqueueMessage, room);
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.isWaitingSeat();
		assert (!result);
	}
}