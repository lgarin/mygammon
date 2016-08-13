import ceylon.json {
	JsonObject = Object
}

shared final class GameMove(shared Integer sourcePosition, shared Integer targetPosition, shared Integer rollValue, shared Boolean hitBlot) extends Object() {
	
	shared JsonObject toJson() => JsonObject({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition, "rollValue" -> rollValue, "hitBlot" -> hitBlot});
	
	shared actual Boolean equals(Object that) {
		if (is GameMove that) {
			return sourcePosition==that.sourcePosition && 
				targetPosition==that.targetPosition && 
				rollValue==that.rollValue && 
				hitBlot==that.hitBlot;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + sourcePosition;
		hash = 31*hash + targetPosition;
		hash = 31*hash + rollValue;
		hash = 31*hash + hitBlot.hash;
		return hash;
	}
	
	string => toJson().string;
}

shared GameMove parseGameMove(JsonObject json) {
	return GameMove(json.getInteger("sourcePosition"), json.getInteger("targetPosition"), json.getInteger("rollValue"), json.getBoolean("hitBlot"));
}