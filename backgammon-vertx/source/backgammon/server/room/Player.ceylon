import backgammon.shared {
	PlayerId,
	TableId,
	MatchId,
	PlayerInfo,
	PlayerState,
	PlayerStatistic,
	MatchState
}

import ceylon.time {
	Instant,
	now
}

final shared class Player(shared PlayerInfo info, PlayerStatistic initialStatistic) {
	
	variable TableId? _tableId = null;
	variable Match? _previousMatch = null;
	variable Match? _match = null;
	variable Instant lastActivity = Instant(0);

	shared TableId? tableId => _tableId;
	shared Match? match => _match;
	shared PlayerId id = PlayerId(info.id);
	
	variable PlayerStatistic _statistic = initialStatistic;
	
	shared PlayerStatistic statistic => _statistic;
	shared Integer balance => _statistic.balance;
	shared PlayerState state => PlayerState(info, _statistic, _tableId, match?.id);

	shared Boolean isAtTable(TableId tableId) => _tableId?.equals(tableId) else false;
	
	shared Boolean isInMatch(MatchId matchId) => match?.id?.equals(matchId) else false;
	
	shared Boolean leaveTable(TableId tableId) {
		if (isPlaying()) {
			return false;
		} else if (!isAtTable(tableId)) {
			return false;
		} else {
			_tableId = null;
			return true;
		}
	}
	
	void unregisterOldMatch(Match currentMatch) {
		if (exists currentTableId = _tableId, currentTableId == currentMatch.tableId) {
			_previousMatch = null;
		} else {
			_previousMatch = currentMatch;
		}
		_match = null;
	}

	shared Boolean joinTable(TableId newTableId) {
		if (isPlaying()) {
			return false;
		} else if (exists currentTableId = _tableId) {
			if (currentTableId == newTableId) {
				return true;
			} if (!leaveTable(currentTableId)) {
				return false;
			}
		}
		
		_tableId = newTableId;
		if (exists currentMatch = _match) {
			unregisterOldMatch(currentMatch);
		}
		return true;
	}
	
	shared Boolean joinMatch(Match currentMatch) {
		if (match exists) {
			return false;
		} else if (currentMatch.gameStarted) {
			return false;
		} else if (!isAtTable(currentMatch.id.tableId)) {
			return false;
		} else if (balance < currentMatch.playerBet) {
			return false;
		} else {
			_match = currentMatch;
			return true;
		}
	}

	shared void increasePlayedGame() {
		_statistic = _statistic.increaseGameCount();
	}
	
	shared void increaseWonGame(Integer score, Integer pot) {
		_statistic = _statistic.increaseWinCount(score).updateBalance(pot);
	}
	
	shared void placeBet(Integer bet) {
		_statistic = _statistic.updateBalance(-bet);
	}

	shared Boolean isPlaying() {
		if (exists currentMatch = match) {
			return currentMatch.hasGame; 
		} else {
			return false;
		}
	}
	
	shared void markActive() {
		lastActivity = now();
	}

	shared Boolean isInactiveSince(Instant timeoutTime) => lastActivity < timeoutTime;
	
	shared MatchState? findRecentMatchState(TableId tableId) {
		if (exists currentMatch = match, currentMatch.tableId == tableId) {
			return currentMatch.state;
		} else if (exists previousMatch = _previousMatch, previousMatch.tableId == tableId) {
			return previousMatch.state;
		} else {
			return null;
		}
	}
}
