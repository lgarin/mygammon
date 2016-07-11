import ceylon.json {
	Object
}

shared final class GameMove(shared Integer sourcePosition, shared Integer targetPosition, shared Integer rollValue, shared Boolean hitBlot) {
	
	shared Object toJson() {
		value result = Object();
		result.put("sourcePosition", sourcePosition);
		result.put("targetPosition", targetPosition);
		result.put("rollValue", rollValue);
		result.put("hitBlot", hitBlot);
		return result;
	}
}

shared GameMove parseGameMove(Object json) {
	return GameMove(json.getInteger("sourcePosition"), json.getInteger("targetPosition"), json.getInteger("rollValue"), json.getBoolean("hitBolt"));
}