import ceylon.json {
	JsonObject = Object,
	JsonArray = Array
}

shared class GameMove(shared Integer sourcePosition, shared Integer targetPosition) extends Object() {
	
	shared default JsonObject toJson() => JsonObject({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition});
	
	shared actual default Boolean equals(Object that) {
		if (is GameMove that) {
			return sourcePosition==that.sourcePosition && 
					targetPosition==that.targetPosition;
		} else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + sourcePosition;
		hash = 31*hash + targetPosition;
		return hash;
	}
	
	string => toJson().string;
}

shared final class GameMoveInfo(Integer sourcePosition, Integer targetPosition, shared Integer rollValue, shared Boolean hitBlot) extends GameMove(sourcePosition, targetPosition) {
	
	shared actual JsonObject toJson() => JsonObject({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition, "rollValue" -> rollValue, "hitBlot" -> hitBlot});
	
	shared actual Boolean equals(Object that) {
		if (is GameMoveInfo that) {
			return sourcePosition==that.sourcePosition && 
				targetPosition==that.targetPosition && 
				rollValue==that.rollValue && 
				hitBlot==that.hitBlot;
		} else {
			return false;
		}
	}
}

shared final class GameMoveSequence(Integer sourcePosition, Integer targetPosition, shared [GameMoveInfo*] moves) extends GameMove(sourcePosition, targetPosition) {
	
	shared actual JsonObject toJson() => JsonObject({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition, "moves" -> JsonArray(moves.map((element) => element.toJson()))});
	
	shared actual Boolean equals(Object that) {
		if (is GameMoveSequence that) {
			return sourcePosition==that.sourcePosition && 
				targetPosition==that.targetPosition &&
				moves == that.moves;
		} else {
			return false;
		}
	}
}

shared GameMoveInfo parseGameMove(JsonObject json) {
	return GameMoveInfo(json.getInteger("sourcePosition"), json.getInteger("targetPosition"), json.getInteger("rollValue"), json.getBoolean("hitBlot"));
}