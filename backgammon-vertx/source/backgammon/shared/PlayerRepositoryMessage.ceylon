import ceylon.json {
	Object
}
import ceylon.language.meta {

	type
}

shared sealed interface PlayerRepositoryMessage of PlayerRepositoryInputMessage | PlayerRepositoryOutputMessage {
	shared formal PlayerId key;
	shared formal Object toJson();
	string => toJson().string;
}

shared sealed interface PlayerRepositoryInputMessage of PlayerRepositoryStoreMessage | PlayerRepositoryRetrieveMessage satisfies PlayerRepositoryMessage {}

shared sealed interface PlayerRepositoryStoreMessage of PlayerStatisticStoreMessage satisfies PlayerRepositoryInputMessage {
	shared formal Object payload;
	shared actual Object toJson() => Object{ key.string -> payload };
}

shared sealed interface PlayerRepositoryRetrieveMessage satisfies PlayerRepositoryInputMessage {
	shared actual Object toJson() => Object{ key.string -> null };
}

shared sealed interface PlayerRepositoryOutputMessage satisfies PlayerRepositoryMessage {
	shared formal Object? payload;
	shared actual Object toJson() => Object{ key.string -> payload };
}

shared final class PlayerStatisticStoreMessage(shared actual PlayerId key, PlayerInfo info, PlayerStatistic statistic) satisfies PlayerRepositoryStoreMessage {
	shared actual Object payload => Object { "info" -> info.toJson(), "stat" -> statistic.toJson() };
}
PlayerStatisticStoreMessage parsePlayerStatisticStoreMessage(Object json) {
	return PlayerStatisticStoreMessage(parsePlayerId(json.getString("key")), parsePlayerInfo(json.getObject("info")), parsePlayerStatistic(json.getObject("stat")));
}

shared final class PlayerStatisticRetrieveMessage(shared actual PlayerId key) satisfies PlayerRepositoryRetrieveMessage {}
PlayerStatisticRetrieveMessage parsePlayerStatisticRetrieveMessage(Object json) {
	return PlayerStatisticRetrieveMessage(parsePlayerId(json.getString("key")));
}

shared final class PlayerStatisticOutputMessage(shared actual PlayerId key, PlayerInfo info, PlayerStatistic statistic) satisfies PlayerRepositoryOutputMessage {
	shared actual Object payload => Object { "info" -> info.toJson(), "stat" -> statistic.toJson() };
}
PlayerStatisticOutputMessage parsePlayerStatisticOutputMessage(Object json) {
	return PlayerStatisticOutputMessage(parsePlayerId(json.getString("key")), parsePlayerInfo(json.getObject("info")), parsePlayerStatistic(json.getObject("stat")));
}


shared Object formatPlayerRepositoryMessage(PlayerRepositoryMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared PlayerRepositoryInputMessage? parsePlayerRepositoryInputMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class PlayerStatisticStoreMessage`.name) {
			return parsePlayerStatisticStoreMessage(json.getObject(typeName));
		} else if (typeName == `class PlayerStatisticRetrieveMessage`.name) {
				return parsePlayerStatisticRetrieveMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}

shared PlayerRepositoryOutputMessage? parsePlayerRepositoryOutputMessage(Object json) {
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