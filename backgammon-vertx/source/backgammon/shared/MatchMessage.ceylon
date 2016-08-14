import ceylon.json {
	Object
}

shared sealed interface MatchMessage of OutboundMatchMessage | InboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	
	shared actual default Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()});
}

shared sealed interface OutboundMatchMessage of AcceptedMatchMessage | LeftMatchMessage | MatchEndedMessage satisfies MatchMessage {}

shared sealed interface InboundMatchMessage of AcceptMatchMessage | EndMatchMessage satisfies MatchMessage {}

shared final class LeftMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared LeftMatchMessage parseLeftMatchMessage(Object json) {
	return LeftMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")));
}

shared final class AcceptedMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Boolean success = true) satisfies OutboundMatchMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
	shared AcceptedMatchMessage withError() => AcceptedMatchMessage(playerId, matchId, false);
}
shared AcceptedMatchMessage parseAcceptedMatchMessage(Object json) {
	return AcceptedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class MatchEndedMessage(shared actual MatchId matchId, shared PlayerId? winnerId, shared actual Boolean success = true) satisfies OutboundMatchMessage & RoomResponseMessage {
	playerId => PlayerId("");
	toJson() => toExtendedJson({"winnerId" -> winnerId?.toJson()});
}
shared MatchEndedMessage parseMatchEndedMessage(Object json) {
	return MatchEndedMessage(parseMatchId(json.getObject("matchId")), json.defines("winnerId") then parsePlayerId(json.getString("winnerId")) else null, json.getBoolean("success"));
}

shared final class AcceptMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies InboundMatchMessage {}
shared AcceptMatchMessage parseAcceptMatchMessage(Object json) {
	return AcceptMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")));
}

shared final class EndMatchMessage(shared actual MatchId matchId, shared PlayerId? winnerId) satisfies InboundMatchMessage {
	playerId => PlayerId("");
	toJson() => toExtendedJson({"winnerId" -> winnerId?.toJson()});
}
shared EndMatchMessage parseEndMatchMessage(Object json) {
	return EndMatchMessage(parseMatchId(json.getObject("matchId")), json.defines("winnerId") then parsePlayerId(json.getString("winnerId")) else null);
}

shared OutboundMatchMessage? parseOutboundMatchMessage(String typeName, Object json) {
	if (typeName == `class LeftMatchMessage`.name) {
		return parseLeftMatchMessage(json);
	} else if (typeName == `class AcceptedMatchMessage`.name) {
		return parseAcceptedMatchMessage(json);
	} else if (typeName == `class MatchEndedMessage`.name) {
		return parseMatchEndedMessage(json);
	} else {
		return null;
	}
}

shared InboundMatchMessage? parseInboundMatchMessage(String typeName, Object json) {
	if (typeName == `class AcceptMatchMessage`.name) {
		return parseAcceptMatchMessage(json);
	} else if (typeName == `class EndMatchMessage`.name) {
		return parseEndMatchMessage(json);
	} else {
		return null;
	}
}