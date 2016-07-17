import ceylon.json {
	Object
}

shared final class PlayerInfo(shared String id, shared String name, shared String? pictureUrl) {
	shared Object toJson() => Object({"id" -> id, "name" -> name, "pictureUrl" -> pictureUrl});
}

shared PlayerInfo parsePlayerInfo(Object json) {
	return PlayerInfo(json.getString("id"), json.getString("name"), json.getStringOrNull("pictureUrl"));
}