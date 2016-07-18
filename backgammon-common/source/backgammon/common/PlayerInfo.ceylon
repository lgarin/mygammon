import ceylon.json {
	Object,
	parse
}
import ceylon.buffer.base {

	base64StringStandard
}
import ceylon.buffer.charset {

	utf8
}

shared final class PlayerInfo(shared String id, shared String name, shared String? pictureUrl) {
	shared Object toJson() => Object({"id" -> id, "name" -> name, "pictureUrl" -> pictureUrl});
	shared String toBase64() => base64StringStandard.encode(utf8.encode(toJson().string));
}

shared PlayerInfo parsePlayerInfo(Object json) {
	return PlayerInfo(json.getString("id"), json.getString("name"), json.getStringOrNull("pictureUrl"));
}

shared PlayerInfo? parseBase64PlayerInfo(String base64) {
	if (is Object json = parse(utf8.decode(base64StringStandard.decode(base64)))) {
		return parsePlayerInfo(json);
	}
	return null;
}