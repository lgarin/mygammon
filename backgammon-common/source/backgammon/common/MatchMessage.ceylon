import ceylon.json {

	Object
}
shared sealed interface MatchMessage of OutboundMatchMessage | GameMessage satisfies TableMessage {
	shared formal MatchId matchId;
	tableId => matchId.tableId;
	shared default actual Object toJson() => Object({"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson()});
}

shared sealed interface OutboundMatchMessage of JoiningMatchMessage | StartMatchMessage | LeaftMatchMessage satisfies MatchMessage {}

shared final class JoiningMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared final class LeaftMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
shared final class StartMatchMessage(shared actual PlayerId playerId, shared actual MatchId matchId) satisfies OutboundMatchMessage {}
