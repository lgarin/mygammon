import ceylon.json {
	Object
}

shared sealed interface MatchMessage of OutboundMatchMessage | InboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	
	shared actual default Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()};
}

shared sealed interface OutboundMatchMessage of AcceptedMatchMessage | MatchEndedMessage satisfies MatchMessage {}

shared sealed interface InboundMatchMessage of AcceptMatchMessage | EndMatchMessage satisfies MatchMessage {}

shared final class AcceptedMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Boolean success = true) satisfies OutboundMatchMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
	shared AcceptedMatchMessage withError() => AcceptedMatchMessage(playerId, matchId, false);
}
AcceptedMatchMessage parseAcceptedMatchMessage(Object json) {
	return AcceptedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class MatchEndedMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared PlayerId winnerId, shared Integer score, shared actual Boolean success = true) satisfies OutboundMatchMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"winnerId" -> winnerId.toJson(), "score" -> score, "success" -> success});
	
	shared Boolean isWinner(PlayerId id) => winnerId == id;
	shared Boolean isLeaver(PlayerId id) => playerId == id;
	shared Boolean isTimeout(PlayerId id) => playerId == systemPlayerId;
}
MatchEndedMessage parseMatchEndedMessage(Object json) {
	return MatchEndedMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("winnerId")), json.getInteger("score"), json.getBoolean("success"));
}

shared final class AcceptMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies InboundMatchMessage {}
AcceptMatchMessage parseAcceptMatchMessage(Object json) {
	return AcceptMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")));
}

shared final class EndMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared PlayerId winnerId, shared Integer score) satisfies InboundMatchMessage {
	toJson() => toExtendedJson({"winnerId" -> winnerId.toJson(), "score" -> score});
	
	shared Boolean isNormalWin => playerId != systemPlayerId && playerId == winnerId;
	shared Boolean isSurrenderWin => playerId != systemPlayerId && playerId != winnerId;
}
EndMatchMessage parseEndMatchMessage(Object json) {
	return EndMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("winnerId")), json.getInteger("score"));
}

shared OutboundMatchMessage? parseOutboundMatchMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class AcceptedMatchMessage`.name) {
			return parseAcceptedMatchMessage(json.getObject(typeName));
		} else if (typeName == `class MatchEndedMessage`.name) {
			return parseMatchEndedMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}

shared InboundMatchMessage? parseInboundMatchMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class AcceptMatchMessage`.name) {
			return parseAcceptMatchMessage(json.getObject(typeName));
		} else if (typeName == `class EndMatchMessage`.name) {
			return parseEndMatchMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}