import ceylon.json {
	Object
}
shared sealed interface MatchMessage of OutboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	
	shared actual default Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()});
}

shared sealed interface OutboundMatchMessage of JoiningMatchMessage | StartMatchMessage | LeaftMatchMessage satisfies MatchMessage {}

shared final class JoiningMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared JoiningMatchMessage parseJoiningMatchMessage(Object json) {
	return JoiningMatchMessage(parsePlayerId(json.get("playerId")), parseMatchId(json.get("matchId")));
}

shared final class LeaftMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared LeaftMatchMessage parseLeaftMatchMessage(Object json) {
	return LeaftMatchMessage(parsePlayerId(json.get("playerId")), parseMatchId(json.get("matchId")));
}

shared final class StartMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared StartMatchMessage parseStartMatchMessage(Object json) {
	return StartMatchMessage(parsePlayerId(json.get("playerId")), parseMatchId(json.get("matchId")));
}

shared MatchMessage? parseMatchMessage(String typeName, Object json) {
	if (typeName == `class JoiningMatchMessage`.name) {
		return parseJoiningMatchMessage(json);
	} else if (typeName == `class LeaftMatchMessage`.name) {
		return parseLeaftMatchMessage(json);
	} else if (typeName == `class StartMatchMessage`.name) {
		return parseStartMatchMessage(json);
	} else {
		return parseGameMessage(typeName, json);
	}
}