import ceylon.json {
	Object
}
import ceylon.language.meta {
	type
}
import ceylon.time {
	Instant,
	now
}

shared sealed interface PlayerRosterMessage of PlayerRosterInboundMessage | PlayerRosterOutboundMessage {
	shared formal PlayerId playerId;
	shared formal Object toJson();
	string => toJson().string;
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

shared Object formatPlayerRosterMessage(PlayerRosterMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared PlayerRosterInboundMessage? parsePlayerRosterInboundMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class PlayerStatisticUpdateMessage`.name) {
			return parsePlayerStatisticUpdateMessage(json.getObject(typeName));
		} else if (typeName == `class PlayerLoginMessage`.name) {
			return parsePlayerLoginMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}

shared PlayerRosterOutboundMessage? parsePlayerRosterOutboundMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class PlayerStatisticOutputMessage`.name) {
			return parsePlayerStatisticOutputMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}