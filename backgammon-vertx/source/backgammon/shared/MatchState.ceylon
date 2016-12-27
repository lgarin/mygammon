import backgammon.shared.game {
	CheckerColor,
	player2Color,
	player1Color
}

import ceylon.json {
	JsonObject = Object
}

shared final class MatchState(shared MatchId id, shared PlayerInfo player1, shared PlayerInfo player2, shared Integer pot, variable Boolean _player1Ready = false, variable Boolean _player2Ready = false, variable PlayerId? _winnerId = null, variable PlayerId? _leaverId = null, variable Integer _score = 0) extends Object() {
	
	shared PlayerId player1Id = PlayerId(player1.id);
	shared PlayerId player2Id = PlayerId(player2.id);
	
	shared Boolean player1Ready => _player1Ready;
	shared Boolean player2Ready => _player2Ready;
	
	shared PlayerId? leaverId => _leaverId;
	shared PlayerId? winnerId => _winnerId;
	shared Integer score => _score;
	
	shared Boolean gameStarted => player1Ready && player2Ready;
	shared Boolean gameEnded => winnerId exists && leaverId exists;
	shared Boolean hasGame => gameStarted && !gameEnded;
	
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
		if (playerId.id == player1.id) {
			return player2Id;
		} else if (playerId.id == player2.id) {
			return player1Id;
		} else {
			return null;
		}
	}
	
	shared void end(PlayerId leaverId, PlayerId winnerId, Integer score) {
		_leaverId = leaverId;
		_winnerId = winnerId;
		_score = score;
	}
	
	shared JsonObject toJson() => JsonObject {"id" -> id.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson(), "pot" -> pot, "player1Ready" -> player1Ready, "player2Ready" -> player2Ready, "winnerId" -> winnerId?.toJson(), "leaverId" -> leaverId?.toJson(), "score" -> score};
	
	shared Boolean hasPlayer(PlayerId playerId) => playerColor(playerId) exists;
	
	string => toJson().string;
	
	shared actual Boolean equals(Object that) {
		if (is MatchState that) {
			return id==that.id && 
				pot==that.pot &&
				_player1Ready==that._player1Ready && 
				_player2Ready==that._player2Ready && 
				_score==that._score && 
				player1Id==that.player1Id && 
				player2Id==that.player2Id;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + id.hash;
		hash = 31*hash + pot.hash;
		hash = 31*hash + _player1Ready.hash;
		hash = 31*hash + _player2Ready.hash;
		hash = 31*hash + _score.hash;
		hash = 31*hash + player1Id.hash;
		hash = 31*hash + player2Id.hash;
		return hash;
	}
}

shared MatchState parseMatchState(JsonObject json) => MatchState(parseMatchId(json.getObject("id")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), json.getInteger("pot"), json.getBoolean("player1Ready"), json.getBoolean("player2Ready"), parseNullablePlayerId(json.getStringOrNull("winnerId")), parseNullablePlayerId(json.getStringOrNull("leaverId")), json.getInteger("score"));

shared MatchState? parseNullableMatchState(JsonObject? json) => if (exists json) then parseMatchState(json) else null;