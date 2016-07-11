import ceylon.time {

	Instant
}
import ceylon.json {
	JsonObject = Object,
	Value
}
shared abstract class StringIdentifier(String id) satisfies Identifiable {
	string = id;
	
	shared actual Boolean equals(Object that) {
		return id == that.string;
	}
	
	shared actual Integer hash => id.hash;
	
	shared formal Value toJson();
}

shared final class RoomId(shared String roomId) extends StringIdentifier(roomId) {
	toJson() => roomId;
}
shared final class TableId(shared String roomId, shared Integer table) extends StringIdentifier("``roomId``-table-``table``") {
	toJson() => JsonObject({"roomId" -> roomId, "table" -> table});
}
shared final class MatchId(shared TableId tableId, shared Instant timestamp) extends StringIdentifier("``tableId``-game-``timestamp.millisecondsOfEpoch``") {
	toJson() => JsonObject({"roomId" -> tableId.roomId, "table" -> tableId.table, "timestamp" -> timestamp.millisecondsOfEpoch});
}
shared final class PlayerId(shared String id) extends StringIdentifier(id) {
	toJson() => id;
}

shared RoomId parseRoomId(Value json) {
	assert (is String json);
	return RoomId(json);
}

shared TableId parseTableId(Value json) {
	assert (is JsonObject json);
	return TableId(json.getString("roomId"), json.getInteger("table"));
}

shared MatchId parseMatchId(Value json) {
	assert (is JsonObject json);
	return MatchId(parseTableId(json), Instant(json.getInteger("timestamp")));
}

shared PlayerId parsePlayerId(Value json) {
	assert (is String json);
	return PlayerId(json);
}