import ceylon.json {

	Object
}
import ceylon.time {

	Duration
}
import backgammon.game {

	CheckerColor,
	player2Color,
	player1Color
}
shared final class MatchState(shared MatchId id, shared PlayerInfo player1, shared PlayerInfo player2, shared Duration remainingJoinTime, shared Boolean player1Ready = false, shared Boolean player2Ready = false, shared PlayerId? winnerId = null) {
	shared Object toJson() => Object({"id" -> id.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson(), "remainingJoinTime" -> remainingJoinTime.milliseconds, "player1Ready" -> player1Ready, "player2Ready" -> player2Ready, "winnerId" -> winnerId?.toJson()});
	shared Boolean gameStarted => player1Ready && player2Ready;
	shared Boolean gameEnded => winnerId exists;
	
	shared PlayerId player1Id = PlayerId(player1.id);
	shared PlayerId player2Id = PlayerId(player2.id);
	
	shared CheckerColor? winnerColor {
		if (exists winnerId, winnerId == player1Id) {
			return player1Color;
		} else if (exists winnerId, winnerId == player2Id) {
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
}

shared MatchState? parseMatchState(Object? json) {
	if (exists json) {
		value winner = json.getStringOrNull("winner") exists then PlayerId(json.getString("winner")) else null;
		return MatchState(parseMatchId(json.getObject("id")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), Duration(json.getInteger("remainingJoinTime")), json.getBoolean("player1Ready"), json.getBoolean("player2Ready"), winner);
	} else {
		return null;
	}
}