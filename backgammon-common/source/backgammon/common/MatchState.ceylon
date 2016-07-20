import ceylon.json {

	Object
}
import ceylon.time {

	Duration
}
shared final class MatchState(shared MatchId id, shared PlayerInfo player1, shared PlayerInfo player2, shared Duration remainingJoinTime, shared Boolean player1Ready, shared Boolean player2Ready, shared PlayerId? winnerId) {
	shared Object toJson() => Object({"id" -> id.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson(), "remainingJoinTime" -> remainingJoinTime.milliseconds, "player1Ready" -> player1Ready, "player2Ready" -> player2Ready, "winnerId" -> winnerId?.toJson()});
	shared Boolean gameStarted => player1Ready && player2Ready;
	shared Boolean gameEnded => winnerId exists;
}

shared MatchState? parseMatchState(Object? json) {
	if (exists json) {
		value winner = json.getStringOrNull("winner") exists then PlayerId(json.getString("winner")) else null;
		return MatchState(parseMatchId(json.getObject("id")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), Duration(json.getInteger("remainingJoinTime")), json.getBoolean("player1Ready"), json.getBoolean("player2Ready"), winner);
	} else {
		return null;
	}
}