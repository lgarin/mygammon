import ceylon.time {

	Instant,
	now,
	Duration,
	Period
}
import ceylon.json {
	Object,
	Array
}
shared final class GameState() {
	
	shared variable CheckerColor? currentColor = null;
	shared variable DiceRoll? currentRoll = null;
	
	shared variable Integer remainingUndo = 0;
	shared variable Boolean blackReady = false;
	shared variable Boolean whiteReady = false;
	shared variable Instant nextTimeout = Instant(0);
	
	shared variable {Integer*} blackCheckerCounts = {};
	shared variable {Integer*} whiteCheckerCounts = {};
	shared variable {GameMove*} currentMoves = {};
	
	shared Boolean canUndoMoves(CheckerColor playerColor) {
		if (exists color = currentColor, color == playerColor) {
			return !currentMoves.empty;
		} else {
			return false;
		}
	}

	shared Boolean mustRollDice(CheckerColor playerColor) {
		if (currentColor exists) {
			return false;
		} else if (!blackReady && playerColor == black) {
			return true;
		} else if (!whiteReady && playerColor == white) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Object toJson() {
		value result = Object();
		result.put("currentColor", currentColor?.name else null);
		result.put("diceValue1", currentRoll?.firstValue else null);
		result.put("diceValue2", currentRoll?.secondValue else null);
		result.put("remainingUndo", remainingUndo);
		result.put("blackReady", blackReady);
		result.put("whiteReady", whiteReady);
		result.put("nextTimeout", nextTimeout.millisecondsOfEpoch);
		result.put("blackCheckerCounts", Array(blackCheckerCounts));
		result.put("whiteCheckerCounts", Array(whiteCheckerCounts));
		result.put("currentMoves", Array(currentMoves.map((element) => element.toJson())));
		return result;
	}
	
	shared Duration remainingTime() => now().durationTo(nextTimeout);
}

shared GameState parseGameState(Object json) {
	value result = GameState();
	if (exists colorName = json.getStringOrNull("currentColor")) {
		result.currentColor = parseCheckerColor(colorName);
	}
	if (exists diceValue1 = json.getIntegerOrNull("diceValue1"), exists diceValue2 = json.getIntegerOrNull("diceValue2")) {
		result.currentRoll = DiceRoll(diceValue1, diceValue2);
	}
	result.remainingUndo = json.getInteger("remainingUndo");
	result.blackReady = json.getBoolean("blackReady");
	result.whiteReady = json.getBoolean("whiteReady");
	result.nextTimeout = Instant(json.getInteger("nextTimeout"));
	result.blackCheckerCounts = json.getArray("blackCheckerCounts").narrow<Integer>();
	result.whiteCheckerCounts = json.getArray("whiteCheckerCounts").narrow<Integer>();
	result.currentMoves = json.getArray("currentMoves").narrow<Object>().collect((element) => parseGameMove(element));
	return result;
}