import ceylon.json {
	Object
}

shared sealed interface MatchMessage of OutboundMatchMessage | InboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	
	shared actual default Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()});
}

shared sealed interface OutboundMatchMessage of AcceptedMatchMessage | LeftMatchMessage | CreatedGameMessage satisfies MatchMessage {}

shared sealed interface InboundMatchMessage of AcceptMatchMessage satisfies MatchMessage {}

shared final class LeftMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared LeftMatchMessage parseLeftMatchMessage(Object json) {
	return LeftMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")));
}

shared final class CreatedGameMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared String name = "backgammon") satisfies OutboundMatchMessage {
	toJson() => toExtendedJson({"name" -> name});
}
shared CreatedGameMessage parseCreatedGameMessage(Object json) {
	return CreatedGameMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getString("name"));
}

shared final class AcceptedMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Boolean success = true) satisfies OutboundMatchMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
	shared AcceptedMatchMessage withError() => AcceptedMatchMessage(playerId, matchId, false);
}
shared AcceptedMatchMessage parseAcceptedMatchMessage(Object json) {
	return AcceptedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class AcceptMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies InboundMatchMessage {}
shared AcceptMatchMessage parseAcceptMatchMessage(Object json) {
	return AcceptMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")));
}

shared OutboundMatchMessage? parseOutboundMatchMessage(String typeName, Object json) {
	if (typeName == `class LeftMatchMessage`.name) {
		return parseLeftMatchMessage(json);
	} else if (typeName == `class AcceptedMatchMessage`.name) {
		return parseAcceptedMatchMessage(json);
	} else if (typeName == `class CreatedGameMessage`.name) {
		return parseCreatedGameMessage(json);
	} else {
		return null;
	}
}

shared InboundMatchMessage? parseInboundMatchMessage(String typeName, Object json) {
	if (typeName == `class AcceptMatchMessage`.name) {
		return parseAcceptMatchMessage(json);
	} else {
		return null;
	}
}