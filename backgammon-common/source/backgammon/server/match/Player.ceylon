import backgammon.common {
	WaitingOpponentMessage,
	JoinedTableMessage,
	PlayerId,
	RoomId,
	RoomMessage,
	PlayerInfo,
	TableId,
	LeftTableMessage,
	MatchId
}

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

final class Player(shared PlayerInfo info, variable Room? room = null) {
	
	shared PlayerId id = PlayerId(info.id);
	
	variable Table? table = null;
	variable Match? match = null;
	variable Instant lastActivity = now(); // TODO is it really necessary?
	
	shared RoomId? roomId => room?.id;
	shared Integer? tableIndex => table?.index;
	shared TableId? tableId => table?.id;
	
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
			currentTable.publish(LeftTableMessage(id, currentTable.id));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean findMatchTable() {
		if (exists currentMatch = match, currentMatch.isStarted && !currentMatch.isEnded) {
			return true;
		} else if (exists currentRoom = room) {
			leaveTable();
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
	
	shared Boolean acceptMatch() {
		lastActivity = now();
		if (exists currentMatch = match) {
			return currentMatch.acceptMatch(this);
		} else {
			return false;
		}
	}
	
	shared MatchId? matchId => match?.id;
	
	shared PlayerId? matchOpponentId => match?.opponentId(id);
	
	shared PlayerId? gameOpponentId {
		if (exists currentMatch = match, currentMatch.isStarted) {
			return currentMatch.opponentId(id);
		} else {
			return null;
		}
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
		return true;
	}
	
	shared Boolean isWaitingOpponent() {
		if (table exists, exists currentMatch = match) {
			return !currentMatch.isStarted;
		} else if (table exists) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
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
	shared void waitingSeatWithoutTable() {
		value result = player.isWaitingOpponent();
		assert (!result);
	}
	
	test
	shared void waitingSeatWithoutMatch() {
		player.joinTable(0);
		value result = player.isWaitingOpponent();
		assert (result);
	}
	
	test
	shared void waitingSeatWithMatch() {
		value opponent = makePlayer("opponent");
		opponent.findMatchTable();
		player.findMatchTable();
		value result = player.isWaitingOpponent();
		assert (!result);
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
