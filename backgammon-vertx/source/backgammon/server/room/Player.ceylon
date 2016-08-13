import backgammon.shared {
	WaitingOpponentMessage,
	JoinedTableMessage,
	PlayerId,
	RoomId,
	TableId,
	LeftTableMessage,
	MatchId,
	PlayerInfo
}

import ceylon.time {
	Instant,
	now
}

final shared class Player(shared PlayerInfo info, variable Room? room = null) {
	
	shared PlayerId id = PlayerId(info.id);
	
	variable Table? table = null;
	variable Match? match = null;
	variable Instant lastActivity = now();
	
	shared RoomId? roomId => room?.id;
	shared Integer? tableIndex => table?.index;
	shared TableId? tableId => table?.id;
	shared MatchId? matchId => match?.id;
	
	shared variable MatchId? previousMatchId = null;
	
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
			previousMatchId = currentMatch.id;
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
	
	shared Boolean isPlaying() {
		if (exists currentMatch = match) {
			return currentMatch.isStarted && !currentMatch.isEnded; 
		} else {
			return false;
		}
	}

	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
}
