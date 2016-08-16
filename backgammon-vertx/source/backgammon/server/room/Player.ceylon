import backgammon.shared {
	PlayerId,
	RoomId,
	TableId,
	MatchId,
	PlayerInfo,
	MatchState
}

import ceylon.time {
	Instant,
	now
}

final shared class Player(shared PlayerInfo info, variable Room? _room = null) {
	
	variable Table? _table = null;
	variable Match? _match = null;
	variable Instant lastActivity = now();

	shared Room? room => _room;
	shared Table? table => _table;
	shared Match? match => _match;
	shared PlayerId id = PlayerId(info.id);	
	
	shared Boolean isInRoom(RoomId roomId) {
		return room?.id?.equals(roomId) else false;
	}
	
	shared Boolean isAtTable(TableId tableId) {
		return table?.id?.equals(tableId) else false;
	}
	
	shared Boolean isInMatch(MatchId matchId) {
		return match?.id?.equals(matchId) else false;
	}
	
	shared Boolean leaveRoom(RoomId roomId) {
		lastActivity = now();
		
		if (!isInRoom(roomId)) {
			return false;
		} else if (table exists) {
			return false;
		} else {
			_room = null;
			return true;
		}
	}
	
	shared Boolean leaveTable(TableId tableId) {
		lastActivity = now();
		
		if (!isAtTable(tableId)) {
			return false;
		} else {
			_table = null;
			return true;
		}
	}

	shared Boolean joinTable(Table newTable) {
		lastActivity = now();
		
		if (!isInRoom(newTable.roomId)) {
			return false;
		} else if (match exists) {
			return false;
		} else if (exists currentTable = table) {
			if (currentTable.id == newTable.id) {
				return true;
			} if (!leaveTable(currentTable.id)) {
				return false;
			}
		}
		
		_table = newTable;
		return true;
	}
	
	shared Boolean joinMatch(Match currentMatch) {
		if (match exists) {
			return false;
		} else if (currentMatch.gameStarted) {
			return false;
		} else if (!isAtTable(currentMatch.id.tableId)) {
			return false;
		}
		
		_match = currentMatch;
		lastActivity = now();
		return true;
	}
	
	shared Boolean acceptMatch(MatchId matchId) {
		lastActivity = now();
		
		if (isInMatch(matchId) && isAtTable(matchId.tableId)) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean leaveMatch(MatchId matchId) {
		lastActivity = now();
		
		if (isInMatch(matchId)) {
			_match = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean isPlaying() {
		if (exists currentMatch = match) {
			return currentMatch.hasGame; 
		} else {
			return false;
		}
	}
	
	shared MatchState? getMatchState(TableId tableId) {
		if (exists currentMatch = match, currentMatch.table.id == tableId) {
			return currentMatch.state;
		} else {
			return null;
		}
	}
	
	shared Boolean terminateMatch(MatchId matchId, PlayerId winnerId) {
		if (exists currentMatch = match, currentMatch.id == matchId) {
			return currentMatch.end(id, winnerId);
		} else {
			return false;
		}
	}
	
	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
	
}
