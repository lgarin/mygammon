import ceylon.json {
	JsonObject = Object,
	parse
}
import ceylon.buffer.base {

	base64StringStandard
}
import ceylon.buffer.charset {

	utf8
}

shared final class PlayerInfo(shared String id, shared String name, shared String? pictureUrl = null, shared String? iconUrl = null) extends Object() {
	shared JsonObject toJson() => JsonObject {"id" -> id, "name" -> name, "pictureUrl" -> pictureUrl, "iconUrl" -> iconUrl};
	shared String toBase64() => base64StringStandard.encode(utf8.encode(toJson().string));
	
	shared actual Boolean equals(Object that) {
		if (is PlayerInfo that) {
			return id==that.id;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash => id.hash;

	string => toJson().string;	
}

shared PlayerInfo parsePlayerInfo(JsonObject json) {
	return PlayerInfo(json.getString("id"), json.getString("name"), json.getStringOrNull("pictureUrl"), json.getStringOrNull("iconUrl"));
}

shared PlayerInfo? parseBase64PlayerInfo(String base64) {
	if (is JsonObject json = parse(utf8.decode(base64StringStandard.decode(base64)))) {
		return parsePlayerInfo(json);
	}
	return null;
}