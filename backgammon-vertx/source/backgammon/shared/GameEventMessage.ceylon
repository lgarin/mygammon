import ceylon.json {
	Object,
	Value
}
import ceylon.language.meta {

	type
}
import backgammon.shared.game {

	DiceRoll
}
import ceylon.time {

	Instant
}

shared sealed interface GameEventMessage of GameTimeoutMessage | NextRollMessage {
	shared formal MatchId matchId;
	shared default String roomId => matchId.roomId;
	shared formal Instant timestamp;
	shared default Object toBaseJson() => Object {"matchId" -> matchId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch};
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
	
	string => toJson().string;
}

shared final class GameTimeoutMessage(shared actual MatchId matchId, shared actual Instant timestamp) satisfies GameEventMessage {
}
shared GameTimeoutMessage parseGameTimeoutMessage(Object json) {
	return GameTimeoutMessage(parseMatchId(json.getObject("matchId")), Instant(json.getInteger("timestamp")));
}

shared final class NextRollMessage(shared actual MatchId matchId, shared DiceRoll roll, shared actual Instant timestamp) satisfies GameEventMessage {
	toJson() => toExtendedJson({"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue});
}
shared NextRollMessage parseNextRollMessage(Object json) {
	return NextRollMessage(parseMatchId(json.getObject("matchId")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Instant(json.getInteger("timestamp")));
}

shared Object formatGameEventMessage(GameEventMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared GameEventMessage? parseGameEventMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class GameTimeoutMessage`.name) {
			return parseGameTimeoutMessage(json.getObject(typeName));
		} else if (typeName == `class NextRollMessage`.name) {
			return parseNextRollMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}