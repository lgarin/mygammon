import ceylon.json {
	JsonObject=Object
}

shared final class PlayerInfo(shared String id, shared String name, shared Integer? level = null) extends Object() {
	shared JsonObject toJson() => JsonObject {"id" -> id, "name" -> name, "level" -> level};
	shared PlayerId playerId => PlayerId(id);
	
	function equalsOrBothNull(Object? object1, Object? object2) {
		if (exists object1, exists object2) {
			return object1 == object2;
		} else {
			return object1 exists == object2 exists;
		}
	}

	shared actual Boolean equals(Object that) {
		if (is PlayerInfo that) {
			return id==that.id && 
				name==that.name && 
				equalsOrBothNull(level, that.level);
		}
		else {
			return false;
		}
	}
	
	
	shared actual Integer hash => id.hash;

	string => toJson().string;
	
	shared PlayerInfo withLevel(Integer level) => PlayerInfo(id, name, level);
}

shared PlayerInfo parsePlayerInfo(JsonObject json) {
	return PlayerInfo(json.getString("id"), json.getString("name"), json.getIntegerOrNull("level"));
}

shared PlayerInfo? parseNullablePlayerInfo(JsonObject? json) => if (exists json) then parsePlayerInfo(json) else null;
