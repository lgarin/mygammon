import ceylon.json {
	Object
}
import ceylon.time {

	Instant,
	now
}

shared sealed interface MatchMessage of OutboundMatchMessage | InboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	
	shared actual default Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()};
}

shared sealed interface OutboundMatchMessage of AcceptedMatchMessage | MatchActivityMessage | MatchEndedMessage satisfies MatchMessage {}

shared sealed interface InboundMatchMessage of AcceptMatchMessage | PingMatchMessage | EndMatchMessage satisfies MatchMessage {
	shared formal Instant timestamp;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch};
}

shared final class AcceptedMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Boolean success = true) satisfies OutboundMatchMessage & StatusResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
}
AcceptedMatchMessage parseAcceptedMatchMessage(Object json) {
	return AcceptedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class MatchActivityMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Boolean success = true) satisfies OutboundMatchMessage & StatusResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
}
MatchActivityMessage parseMatchActivityMessage(Object json) {
	return MatchActivityMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class MatchEndedMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared PlayerId winnerId, shared Integer score, shared actual Boolean success = true) satisfies OutboundMatchMessage & StatusResponseMessage {
	toJson() => toExtendedJson({"winnerId" -> winnerId.toJson(), "score" -> score, "success" -> success});
	
	shared Boolean isWinner(PlayerId id) => winnerId == id;
	shared Boolean isLeaver(PlayerId id) => playerId == id;
	shared Boolean isTimeout(PlayerId id) => playerId == systemPlayerId;
}
MatchEndedMessage parseMatchEndedMessage(Object json) {
	return MatchEndedMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("winnerId")), json.getInteger("score"), json.getBoolean("success"));
}

shared final class AcceptMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Instant timestamp = now()) satisfies InboundMatchMessage {}
AcceptMatchMessage parseAcceptMatchMessage(Object json) {
	return AcceptMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), Instant(json.getInteger("timestamp")));
}

shared final class PingMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared actual Instant timestamp = now()) satisfies InboundMatchMessage {}
PingMatchMessage parsePingMatchMessage(Object json) {
	return PingMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), Instant(json.getInteger("timestamp")));
}

shared final class EndMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId, shared PlayerId winnerId, shared Integer score, shared actual Instant timestamp = now()) satisfies InboundMatchMessage {
	toJson() => toExtendedJson({"winnerId" -> winnerId.toJson(), "score" -> score});
	
	shared Boolean isAbandonedMatch => playerId == systemPlayerId && playerId == winnerId;
	shared Boolean isNormalWin => playerId != systemPlayerId && playerId == winnerId;
	shared Boolean isSurrenderWin => playerId != systemPlayerId && playerId != winnerId;
}
EndMatchMessage parseEndMatchMessage(Object json) {
	return EndMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("winnerId")), json.getInteger("score"), Instant(json.getInteger("timestamp")));
}
