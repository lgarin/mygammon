import backgammon.common {
	JoiningMatchMessage,
	LeaftTableMessage,
	WaitingOpponentMessage,
	JoinedTableMessage,
	PlayerId,
	RoomId,
	PlayerMessage
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
import ceylon.time {
	Instant,
	now,
	Duration
}

final class Player(String playerId, variable Room? room = null) {
	
	shared PlayerId id = PlayerId(playerId);
	
	variable Table? table = null;
	variable Match? match = null;
	variable Instant lastActivity = now();
	
	shared RoomId? roomId => room?.id;
	shared Integer? tableIndex => table?.index;
	
	shared Boolean isInRoom(RoomId roomId) {
		return room?.id?.equals(roomId) else false;
	}
	
	shared Boolean leaveRoom() {
		leaveTable();
		if (exists currentRoom = room) {
			currentRoom.removePlayer(this);
			room = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean leaveTable() {
		leaveMatch();
		
		if (exists currentTable = table) {
			currentTable.removePlayer(this);
			table = null;
			currentTable.publish(LeaftTableMessage(id, currentTable.id));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean findMatchTable() {
		if (exists currentRoom = room) {
			return currentRoom.sitPlayer(this);
		} else {
			return false;
		}
	}
	
	Boolean doJoinTable(Table currentTable) {
		leaveTable();
		
		table = currentTable;
		lastActivity = now();
		currentTable.publish(JoinedTableMessage(id, currentTable.id));
		value seated = currentTable.sitPlayer(this);
		if (seated && match is Null) {
			currentTable.publish(WaitingOpponentMessage(id, currentTable.id));
		}
		return true;
	}
	
	shared Boolean joinTable(Integer tableIndex) {
		if (exists currentRoom = room) {
			value table = currentRoom.tables[tableIndex];
			if (exists currentTable = table) {
				return doJoinTable(currentTable);
			}
		}
		return false;
	}
	
	shared Boolean startGame() {
		lastActivity = now();
		return match?.startGame(this) else false;
	}
	
	shared Boolean leaveMatch() {
		if (exists currentMatch = match) {
			currentMatch.end(this);
			match = null;
			return true;
		}
		return false;
	}
	
	shared Boolean joinMatch(Match currentMatch) {
		if (currentMatch.isStarted) {
			return false;
		}
		
		leaveMatch();
		
		match = currentMatch;
		lastActivity = now();
		currentMatch.table.publish(JoiningMatchMessage(id, currentMatch.id));
		return true;
	}
	
	shared Boolean isWaitingSeat() => table exists && match is Null;
	
	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
}

class PlayerTest() {
	
	value messageList = ArrayList<PlayerMessage>();
	
	value room = Room("room", 1, Duration(1000), messageList.add);
	value player = Player("player", room);
	
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
		value opponent = Player("opponent", room);
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
		value opponent = Player("opponent", room);
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
		value opponent = Player("opponent", room);
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.isWaitingSeat();
		assert (!result);
	}
	
	test
	shared void joinMatch() {
		value opponent = Player("opponent", room);
		value table = Table(0, room.id, Duration(1000), messageList.add);
		value match = Match(player, opponent, table);
		value result = player.joinMatch(match);
		assert (result);
	}
	
	test
	shared void joinStartedMatch() {
		value opponent = Player("opponent", room);
		value table = Table(0, room.id, Duration(1000), messageList.add);
		value match = Match(player, opponent, table);
		match.startGame(opponent);
		match.startGame(player);
		value result = player.joinMatch(match);
		assert (!result);
	}
}
