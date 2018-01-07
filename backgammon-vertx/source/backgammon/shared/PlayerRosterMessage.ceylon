import ceylon.json {
	Object
}
import ceylon.time {
	Instant,
	now
}

shared sealed interface PlayerRosterMessage of PlayerRosterInboundMessage | PlayerRosterOutboundMessage satisfies ApplicationMessage {
	shared formal PlayerId playerId;
}

shared sealed interface PlayerRosterInboundMessage of PlayerStatisticUpdateMessage | PlayerLoginMessage satisfies PlayerRosterMessage {
	shared formal Instant timestamp;
}

shared sealed interface PlayerRosterOutboundMessage of PlayerStatisticOutputMessage satisfies PlayerRosterMessage {}

shared final class PlayerStatisticUpdateMessage(shared PlayerInfo playerInfo, shared PlayerStatistic statisticDelta, shared actual Instant timestamp = now()) satisfies PlayerRosterInboundMessage {
	playerId = playerInfo.playerId;
	toJson() => Object { "playerInfo" -> playerInfo.toJson(), "statisticDelta" -> statisticDelta.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	shared Boolean isBet => statisticDelta.playedGames == 0 && statisticDelta.balance < 0;
	shared Boolean isWonGame => statisticDelta.wonGames > 0;
	shared Boolean isLostGame => statisticDelta.wonGames == 0 && statisticDelta.playedGames > 0;
	shared Boolean isRefund =>  statisticDelta.playedGames > 0 && statisticDelta.balance > 0;
}
PlayerStatisticUpdateMessage parsePlayerStatisticUpdateMessage(Object json) {
	return PlayerStatisticUpdateMessage(parsePlayerInfo(json.getObject("playerInfo")), parsePlayerStatistic(json.getObject("statisticDelta")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerLoginMessage(shared PlayerInfo playerInfo, shared actual Instant timestamp = now()) satisfies PlayerRosterInboundMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
}
PlayerLoginMessage parsePlayerLoginMessage(Object json) {
	return PlayerLoginMessage(parsePlayerInfo(json.getObject("playerInfo")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerStatisticOutputMessage(shared actual PlayerId playerId, shared PlayerStatistic statistic) satisfies PlayerRosterOutboundMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "statistic" -> statistic.toJson() };
}
PlayerStatisticOutputMessage parsePlayerStatisticOutputMessage(Object json) {
	return PlayerStatisticOutputMessage(parsePlayerId(json.getString("playerId")), parsePlayerStatistic(json.getObject("statistic")));
}
