import backgammon.shared.game {
	CheckerColor,
	player2Color,
	player1Color
}

import ceylon.json {
	Object
}

shared final class MatchState(shared MatchId id, shared PlayerInfo player1, shared PlayerInfo player2, variable Boolean _player1Ready = false, variable Boolean _player2Ready = false, variable PlayerId? _winnerId = null, variable PlayerId? _leaverId = null) {
	
	shared PlayerId player1Id = PlayerId(player1.id);
	shared PlayerId player2Id = PlayerId(player2.id);
	
	shared Boolean player1Ready => _player1Ready;
	shared Boolean player2Ready => _player2Ready;
	
	shared PlayerId? leaverId => _leaverId;
	shared PlayerId? winnerId => _winnerId;
	
	shared Boolean gameStarted => player1Ready && player2Ready;
	shared Boolean gameEnded => winnerId exists && leaverId exists; 
	
	shared CheckerColor? winnerColor {
		if (exists currentWinnerId = winnerId, currentWinnerId == player1Id) {
			return player1Color;
		} else if (exists currentWinnerId = winnerId, currentWinnerId == player2Id) {
			return player2Color;
		} else {
			return null;
		}
	}
	shared Boolean mustStartMatch(PlayerId playerId) {
		if (playerId == player1Id) {
			return !player1Ready;
		} else if (playerId == player2Id) {
			return !player2Ready;
		} else {
			return false;
		}
	}

	shared CheckerColor? playerColor(PlayerId playerId) {
		if (playerId == player1Id) {
			return player1Color;
		} else if (playerId == player2Id) {
			return player2Color;
		} else {
			return null;
		}
	}
	
	shared Boolean markReady(PlayerId playerId) {
		if (gameStarted || gameEnded) {
			return false;
		} else if (playerId == player1Id) {
			_player1Ready = true;
			return true;
		} else if (playerId == player2Id) {
			_player2Ready = true;
			return true;
		} else {
			return false;
		}
	}
	
	shared PlayerId? opponentId(PlayerId playerId) {
		if (playerId == player1.id) {
			return player2Id;
		} else if (playerId == player2.id) {
			return player1Id;
		} else {
			return null;
		}
	}
	
	shared void end(PlayerId leaverId, PlayerId winnerId) {
		_leaverId = leaverId;
		_winnerId = winnerId;
	}
	
	shared Object toJson() => Object({"id" -> id.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson(), "player1Ready" -> player1Ready, "player2Ready" -> player2Ready, "winnerId" -> winnerId?.toJson(), "leaverId" -> leaverId?.toJson()});
}

shared MatchState? parseMatchState(Object? json) {
	if (exists json) {
		value winnerId = json.getStringOrNull("winnerId") exists then PlayerId(json.getString("winnerId")) else null;
		value leaverId = json.getStringOrNull("leaverId") exists then PlayerId(json.getString("leaverId")) else null;
		return MatchState(parseMatchId(json.getObject("id")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), json.getBoolean("player1Ready"), json.getBoolean("player2Ready"), winnerId, leaverId);
	} else {
		return null;
	}
}