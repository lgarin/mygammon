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
shared sealed interface DiceRollMessage of DiceRollInboundMessage | DiceRollOutboundMessage {
	shared formal MatchId matchId;
	shared default Object toBaseJson() => Object {"matchId" -> matchId.toJson()};
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
	
	string => toJson().string;
}

shared interface DiceRollInboundMessage of GenerateRollMessage satisfies DiceRollMessage {}

shared final class GenerateRollMessage(shared actual MatchId matchId) satisfies DiceRollInboundMessage {
}
shared GenerateRollMessage parseGenerateRollMessage(Object json) {
	return GenerateRollMessage(parseMatchId(json.getObject("matchId")));
}

shared interface DiceRollOutboundMessage of NewRollMessage satisfies DiceRollMessage {}

shared final class NewRollMessage(shared actual MatchId matchId, shared DiceRoll roll) satisfies DiceRollOutboundMessage {
	toJson() => toExtendedJson({"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue});
}
shared NewRollMessage parseNewRollMessage(Object json) {
	return NewRollMessage(parseMatchId(json.getObject("matchId")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")));
}

shared Object formatDiceRollMessage(DiceRollMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}
