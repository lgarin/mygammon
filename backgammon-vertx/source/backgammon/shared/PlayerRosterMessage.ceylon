import ceylon.json {
	Object,
	JsonArray
}
import ceylon.time {
	Instant,
	now
}

shared sealed interface PlayerRosterMessage of InboundPlayerRosterMessage | OutboundPlayerRosterMessage satisfies ApplicationMessage {
	shared formal PlayerId playerId;
}

shared sealed interface InboundPlayerRosterMessage of PlayerStatisticUpdateMessage | PlayerLoginMessage | PlayerDetailRequestMessage | PlayerStatisticRequestMessage | PlayerInfoRequestMessage satisfies PlayerRosterMessage {
	shared formal Instant timestamp;
}

shared sealed interface OutboundPlayerRosterMessage of PlayerStatisticOutputMessage | PlayerDetailOutputMessage | PlayerInfoOutputMessage satisfies PlayerRosterMessage {}

shared final class PlayerStatisticUpdateMessage(shared PlayerInfo playerInfo, shared PlayerStatistic statisticDelta, shared actual Instant timestamp = now()) satisfies InboundPlayerRosterMessage {
	playerId = playerInfo.playerId;
	toJson() => Object { "playerInfo" -> playerInfo.toJson(), "statisticDelta" -> statisticDelta.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	shared Boolean hasBalanceDelta => statisticDelta.balance != 0;
	shared Boolean isBet => statisticDelta.playedGames == 0 && statisticDelta.balance < 0;
	shared Boolean isWonGame => statisticDelta.wonGames > 0;
	shared Boolean isLostGame => statisticDelta.wonGames == 0 && statisticDelta.playedGames > 0;
	shared Boolean isRefund =>  statisticDelta.playedGames > 0 && statisticDelta.balance > 0;
	shared Boolean isLogin => statisticDelta.playedGames == 0 && statisticDelta.balance > 0;
}
PlayerStatisticUpdateMessage parsePlayerStatisticUpdateMessage(Object json) {
	return PlayerStatisticUpdateMessage(parsePlayerInfo(json.getObject("playerInfo")), parsePlayerStatistic(json.getObject("statisticDelta")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerLoginMessage(shared PlayerInfo playerInfo, shared actual Instant timestamp = now()) satisfies InboundPlayerRosterMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
}
PlayerLoginMessage parsePlayerLoginMessage(Object json) {
	return PlayerLoginMessage(parsePlayerInfo(json.getObject("playerInfo")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerDetailRequestMessage(shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundPlayerRosterMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
PlayerDetailRequestMessage parsePlayerDetailRequestMessage(Object json) {
	return PlayerDetailRequestMessage(parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerStatisticRequestMessage(shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundPlayerRosterMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
PlayerStatisticRequestMessage parsePlayerStatisticRequestMessage(Object json) {
	return PlayerStatisticRequestMessage(parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerInfoRequestMessage(shared actual PlayerId playerId, shared [PlayerId*] otherPlayerIds = [], shared actual Instant timestamp = now()) satisfies InboundPlayerRosterMessage {
	shared [PlayerId+] playerIds => [playerId, *otherPlayerIds];
	toJson() => Object{ "playerIds" -> JsonArray({playerId, *otherPlayerIds}*.toJson()), "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
PlayerInfoRequestMessage parsePlayerInfoRequestMessage(Object json) {
	return PlayerInfoRequestMessage(parsePlayerId(json.getString("playerId")), json.getArray("requestedIds").narrow<String>().collect(parsePlayerId), Instant(json.getInteger("timestamp")));
}

shared final class PlayerDetailOutputMessage(shared PlayerInfo playerInfo, shared PlayerStatistic statistic, shared [PlayerTransaction*] transactions) satisfies OutboundPlayerRosterMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "statistic" -> statistic.toJson(), "transactions" -> JsonArray(transactions*.toJson()) };
}
PlayerDetailOutputMessage parsePlayerDetailOutputMessage(Object json) {
	return PlayerDetailOutputMessage(parsePlayerInfo(json.getObject("playerInfo")), parsePlayerStatistic(json.getObject("statistic")), json.getArray("transactions").narrow<Object>().collect(parsePlayerTransaction));
}

shared final class PlayerStatisticOutputMessage(shared PlayerInfo playerInfo, shared PlayerStatistic statistic) satisfies OutboundPlayerRosterMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "statistic" -> statistic.toJson() };
}
PlayerStatisticOutputMessage parsePlayerStatisticOutputMessage(Object json) {
	return PlayerStatisticOutputMessage(parsePlayerInfo(json.getObject("playerInfo")), parsePlayerStatistic(json.getObject("statistic")));
}

shared final class PlayerInfoOutputMessage(shared [PlayerInfo+] playerInfoSet) satisfies OutboundPlayerRosterMessage & Correspondence<PlayerId, PlayerInfo> {
	playerId = playerInfoSet.first.playerId;
	toJson() => Object{ "playerInfoSet" -> JsonArray(playerInfoSet*.toJson()) };
	value internalMap = map({for (playerInfo in playerInfoSet) playerInfo.playerId -> playerInfo});
	shared actual Boolean defines(PlayerId key) => internalMap.defines(key);
	shared actual PlayerInfo? get(PlayerId key) => internalMap.get(key);
	
	
}
PlayerInfoOutputMessage parsePlayerInfoOutputMessage(Object json) {
	value array = json.getArray("playerInfoSet").narrow<Object>().collect(parsePlayerInfo);
	if (nonempty array) {
		return PlayerInfoOutputMessage(array);
	} else {
		throw Exception("empty playerInfoSet");
	}
}