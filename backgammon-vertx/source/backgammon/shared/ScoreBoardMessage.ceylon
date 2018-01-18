import ceylon.time {

	Instant,
	now
}
import ceylon.json {

	Object
}
import backgammon.shared.game {

	GameStatistic
}
shared sealed interface ScoreBoardMessage of InboundScoreBoardMessage | OutboundScoreBoardMessage satisfies ApplicationMessage {
}

shared sealed interface InboundScoreBoardMessage of NewGameStatisticMessage satisfies ScoreBoardMessage {
	shared formal Instant timestamp;
}

shared sealed interface OutboundScoreBoardMessage of ScoreBoardResponseMessage satisfies ScoreBoardMessage {}

shared final class NewGameStatisticMessage(shared MatchId matchId, shared PlayerInfo blackPlayer, shared PlayerInfo whitePlayer, shared GameStatistic statistic, shared actual Instant timestamp = now()) satisfies InboundScoreBoardMessage {
	toJson() => Object { "matchId" -> matchId.toJson(), "blackPlayer" -> blackPlayer.toJson(), "whitePlayer" -> whitePlayer.toJson(), "statistic" -> statistic.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
}
NewGameStatisticMessage parseNewGameStatisticMessage(Object json) {
	return NewGameStatisticMessage(parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("blackPlayer")), parsePlayerInfo(json.getObject("whitePlayer")), GameStatistic.fromJson(json.getObject("statistic")), Instant(json.getInteger("timestamp")));
}

shared final class ScoreBoardResponseMessage(shared MatchId matchId, shared actual Boolean success) satisfies OutboundScoreBoardMessage & StatusResponseMessage {
	toJson() => Object {"matchId" -> matchId.toJson(), "success" -> success};
}
ScoreBoardResponseMessage parseScoreBoardResponseMessage(Object json) {
	return ScoreBoardResponseMessage(parseMatchId(json.getObject("matchId")), json.getBoolean("success"));
}