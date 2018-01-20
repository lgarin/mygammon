import ceylon.time {

	Instant,
	now
}
import ceylon.json {

	JsonArray,
	JsonObject
}
import backgammon.shared.game {

	GameStatistic
}
shared sealed interface ScoreBoardMessage of InboundScoreBoardMessage | OutboundScoreBoardMessage satisfies ApplicationMessage {
}

shared sealed interface InboundScoreBoardMessage of GameStatisticMessage | QueryGameStatisticMessage satisfies ScoreBoardMessage {
	shared formal Instant timestamp;
	shared formal PlayerId playerId;
}

shared sealed interface OutboundScoreBoardMessage of ScoreBoardResponseMessage | GameStatisticResponseMessage satisfies ScoreBoardMessage {}

shared final class GameStatisticMessage(shared MatchId matchId, shared PlayerInfo blackPlayer, shared PlayerInfo whitePlayer, shared GameStatistic statistic, shared actual Instant timestamp = now()) satisfies InboundScoreBoardMessage {
	playerId => systemPlayerId;
	toJson() => JsonObject { "matchId" -> matchId.toJson(), "blackPlayer" -> blackPlayer.toJson(), "whitePlayer" -> whitePlayer.toJson(), "statistic" -> statistic.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
}
GameStatisticMessage parseGameStatisticMessage(JsonObject json) {
	return GameStatisticMessage(parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("blackPlayer")), parsePlayerInfo(json.getObject("whitePlayer")), GameStatistic.fromJson(json.getObject("statistic")), Instant(json.getInteger("timestamp")));
}
[GameStatisticMessage*] parseGameStatisticArray(JsonArray json) => json.narrow<JsonObject>().map(parseGameStatisticMessage).sequence();

shared final class QueryGameStatisticMessage(shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundScoreBoardMessage {
	toJson() => JsonObject { "playerId" -> playerId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
QueryGameStatisticMessage parseQueryGameStatisticMessage(JsonObject json) {
	return QueryGameStatisticMessage(parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class ScoreBoardResponseMessage(shared MatchId matchId, shared actual Boolean success) satisfies OutboundScoreBoardMessage & StatusResponseMessage {
	toJson() => JsonObject {"matchId" -> matchId.toJson(), "success" -> success};
}
ScoreBoardResponseMessage parseScoreBoardResponseMessage(JsonObject json) {
	return ScoreBoardResponseMessage(parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}

shared final class GameStatisticResponseMessage(shared PlayerStatistic playerStatistic, [GameStatisticMessage*] gameHistory) satisfies OutboundScoreBoardMessage {
	toJson() => JsonObject {"playerStatistic" -> playerStatistic.toJson(), "gameHistory" -> JsonArray(gameHistory*.toJson()) };
}
GameStatisticResponseMessage parseGameStatisticResponseMessage(JsonObject json) {
	return GameStatisticResponseMessage(parsePlayerStatistic(json.getObject("playerStatistic")), parseGameStatisticArray(json.getArray("gameHistory")));
}