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
	Instant
}

final shared class Player(shared PlayerInfo info, PlayerStatistic initialStatistic) {
	
	variable TableId? _tableId = null;
	variable Match? _previousMatch = null;
	variable Match? _match = null;
	variable Instant lastActivity = Instant(0);

	shared TableId? tableId => _tableId;
	shared Match? match => _match;
	shared Match? previousMatch => _previousMatch;
	shared PlayerId id = PlayerId(info.id);
	
	variable PlayerStatistic _statistic = initialStatistic;
	variable PlayerStatistic _statisticDelta = PlayerStatistic();
	
	shared PlayerStatistic statistic => _statistic + _statisticDelta;
	shared Integer balance => _statistic.balance + _statisticDelta.balance;
	shared PlayerState state => PlayerState(info, _statistic, _tableId, match?.id);

	shared Boolean isAtTable(TableId tableId) => _tableId?.equals(tableId) else false;
	
	shared Boolean wasAtTable(TableId tableId) => _previousMatch?.tableId?.equals(tableId) else false;
	
	shared Boolean isInMatch(MatchId matchId) => match?.id?.equals(matchId) else false;
	
	shared Boolean leaveTable(TableId tableId) {
		if (!isAtTable(tableId)) {
			return false;
		} else {
			_tableId = null;
			_previousMatch = _match;
			_match = null;
			return true;
		}
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
		_previousMatch = null;
		_match = null;
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
			_previousMatch = _match;
			_match = currentMatch;
			return true;
		}
	}

	shared void increasePlayedGame() {
		_statisticDelta = _statisticDelta.increaseGameCount();
	}
	
	shared void increaseWonGame(Integer score, Integer pot) {
		_statisticDelta = _statisticDelta.increaseWinCount(score).updateBalance(pot);
	}
	
	shared void placeBet(Integer bet) {
		_statisticDelta = _statisticDelta.updateBalance(-bet);
	}
	
	shared void refundBet(Integer bet) {
		_statisticDelta = _statisticDelta.updateBalance(bet);
	}

	shared Boolean isPlaying() {
		if (exists currentMatch = match) {
			return currentMatch.hasGame; 
		} else {
			return false;
		}
	}
	
	shared void markActive(Instant timestamp) {
		lastActivity = timestamp;
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
	
	shared PlayerStatistic? applyStatisticDelta() {
		value result = _statisticDelta;
		value initial = PlayerStatistic();
		if (result == initial) {
			return null; 
		}
		_statistic += result;
		_statisticDelta = initial;
		return result;
	}
}
