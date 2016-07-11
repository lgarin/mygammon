import ceylon.json {

	Object
}
shared final class MatchInfo(shared MatchId id, shared PlayerInfo player1, shared PlayerInfo player2) {
	shared Object toJson() => Object({"id" -> id.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson()});
}

shared MatchInfo parseMatchInfo(Object json) {
	return MatchInfo(parseMatchId(json.get("id")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")));
}