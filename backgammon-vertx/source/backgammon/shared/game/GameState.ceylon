import ceylon.json {
	JsonObject = Object,
	JsonArray = Array
}
import ceylon.time {
	Duration
}

shared final class GameState() extends Object() {
	
	shared variable CheckerColor? currentColor = null;
	shared variable DiceRoll? currentRoll = null;
	
	shared variable Integer remainingUndo = 0;
	shared variable Boolean blackReady = false;
	shared variable Boolean whiteReady = false;
	shared variable Duration? remainingTime = null;
	
	shared variable Integer blackJoker = 0;
	shared variable Integer whiteJoker = 0;
	
	shared variable [Integer*] blackCheckerCounts = [];
	shared variable [Integer*] whiteCheckerCounts = [];
	shared variable [GameMoveInfo*] currentMoves = [];
	
	shared JsonObject toJson() {
		value result = JsonObject();
		result.put("currentColor", currentColor?.name else null);
		result.put("diceValue1", currentRoll?.firstValue else null);
		result.put("diceValue2", currentRoll?.secondValue else null);
		result.put("remainingDiceValues", JsonArray(currentRoll?.remainingValues else {}));
		result.put("remainingUndo", remainingUndo);
		result.put("blackReady", blackReady);
		result.put("whiteReady", whiteReady);
		result.put("remainingTime", remainingTime?.milliseconds);
		result.put("blackJoker", blackJoker);
		result.put("whiteJoker", whiteJoker);
		result.put("blackCheckerCounts", JsonArray(blackCheckerCounts));
		result.put("whiteCheckerCounts", JsonArray(whiteCheckerCounts));
		result.put("currentMoves", JsonArray {for (e in currentMoves) e.toJson()});
		return result;
	}
	
	function equalsOrBothNull(Object? object1, Object? object2) {
		if (exists object1, exists object2) {
			return object1 == object2;
		} else {
			return object1 exists == object2 exists;
		}
	}
	
	shared actual Boolean equals(Object that) {
		if (is GameState that) {
			return equalsOrBothNull(currentColor, that.currentColor) &&
				equalsOrBothNull(currentRoll, that.currentRoll) &&
				remainingUndo==that.remainingUndo && 
				blackReady==that.blackReady && 
				whiteReady==that.whiteReady && 
				equalsOrBothNull(remainingTime, that.remainingTime) &&
				blackCheckerCounts.sequence()==that.blackCheckerCounts.sequence() && 
				whiteCheckerCounts.sequence()==that.whiteCheckerCounts.sequence() && 
				currentMoves.sequence()==that.currentMoves.sequence();
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + (currentColor?.hash else 0);
		hash = 31*hash + (currentRoll?.hash else 0);
		hash = 31*hash + blackReady.hash;
		hash = 31*hash + whiteReady.hash;
		hash = 31*hash + blackCheckerCounts.hash;
		hash = 31*hash + whiteCheckerCounts.hash;
		return hash;
	}
	
	string => toJson().string;
}

shared GameState parseGameState(JsonObject json) {
	value result = GameState();
	if (exists colorName = json.getStringOrNull("currentColor")) {
		result.currentColor = parseCheckerColor(colorName);
	}
	if (exists diceValue1 = json.getIntegerOrNull("diceValue1"), exists diceValue2 = json.getIntegerOrNull("diceValue2")) {
		value roll = DiceRoll(diceValue1, diceValue2);
		roll.resetRemainingValues(json.getArray("remainingDiceValues").narrow<Integer>());
		result.currentRoll = roll;
	}
	result.remainingUndo = json.getInteger("remainingUndo");
	result.blackReady = json.getBoolean("blackReady");
	result.whiteReady = json.getBoolean("whiteReady");
	result.remainingTime = json.getIntegerOrNull("remainingTime") exists then Duration(json.getInteger("remainingTime")) else null;
	result.blackJoker = json.getInteger("blackJoker");
	result.whiteJoker = json.getInteger("whiteJoker");
	result.blackCheckerCounts = json.getArray("blackCheckerCounts").narrow<Integer>().sequence();
	result.whiteCheckerCounts = json.getArray("whiteCheckerCounts").narrow<Integer>().sequence();
	result.currentMoves = json.getArray("currentMoves").narrow<JsonObject>().collect(parseGameMove);
	return result;
}