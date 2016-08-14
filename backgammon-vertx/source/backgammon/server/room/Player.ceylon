import backgammon.shared {
	JoinedTableMessage,
	PlayerId,
	RoomId,
	TableId,
	LeftTableMessage,
	MatchId,
	PlayerInfo,
	AcceptedMatchMessage,
	MatchState
}

import ceylon.time {
	Instant,
	now
}

final shared class Player(shared PlayerInfo info, variable Room? room = null) {
	
	variable Table? table = null;
	variable MatchState? match = null;
	variable Instant lastActivity = now();

	shared PlayerId id = PlayerId(info.id);	
	shared RoomId? roomId => room?.id;
	shared Integer? tableIndex => table?.index;
	shared TableId? tableId => table?.id;
	shared MatchId? matchId => match?.id;
	
	shared MatchId? gameMatchId => if (isPlaying()) then match?.id else null;
	
	shared Boolean isInRoom(RoomId roomId) {
		return room?.id?.equals(roomId) else false;
	}
	
	shared Boolean isAtTable(TableId tableId) {
		return table?.id?.equals(tableId) else false;
	}
	
	shared Boolean isInMatch(MatchId matchId) {
		return match?.id?.equals(matchId) else false;
	}
	
	shared Boolean leaveRoom() {
		lastActivity = now();
		
		if (table exists) {
			return false;
		}
		
		if (exists currentRoom = room) {
			room = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean leaveTable() {
		lastActivity = now();
		
		if (exists currentTable = table) {
			table = null;
			match = null;
			currentTable.publish(LeftTableMessage(id, currentTable.id));
			return true;
		} else {
			return false;
		}
	}

	shared Boolean joinTable(Table currentTable) {
		lastActivity = now();
		
		if (exists existingTable = table) {
			if (existingTable.id == currentTable.id) {
				return true;
			} if (!leaveTable()) {
				return false;
			}
		} else if (!isInRoom(currentTable.roomId)) {
			return false;
		}
		
		table = currentTable;
		currentTable.publish(JoinedTableMessage(id, currentTable.id));
		return true;
	}
	
	shared Boolean joinMatch(MatchState currentMatch) {
		if (match exists) {
			return false;
		} else if (currentMatch.gameStarted) {
			return false;
		} else if (!isAtTable(currentMatch.id.tableId)) {
			return false;
		}
		
		match = currentMatch;
		lastActivity = now();
		return true;
	}
	
	shared Boolean acceptMatch(MatchId matchId) {
		lastActivity = now();
		
		if (exists currentMatch = match, currentMatch.id == matchId, exists currentTable = table) {
			if (currentMatch.markReady(id)) {
				currentTable.publish(AcceptedMatchMessage(id, currentMatch.id));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared Boolean isPlaying() {
		if (exists currentMatch = match) {
			return currentMatch.gameStarted && !currentMatch.gameEnded; 
		} else {
			return false;
		}
	}

	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
}
