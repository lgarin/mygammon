import ceylon.json {
	JsonObject=Object,
	Value
}
import ceylon.time {
	Instant
}
shared abstract class StringIdentifier(String id) extends Object() {
	string = id;
	
	shared actual Boolean equals(Object that) => id == that.string;
	
	shared actual Integer hash => id.hash;
	
	shared formal Value toJson();
}

shared final class RoomId(shared String roomId) extends StringIdentifier(roomId) {
	toJson() => roomId;
}
shared final class TableId(shared String roomId, shared Integer table) extends StringIdentifier("``roomId``-table-``table``") {
	toJson() => JsonObject {"roomId" -> roomId, "table" -> table};
}
shared final class MatchId(shared TableId tableId, shared Instant timestamp) extends StringIdentifier("``tableId``-game-``timestamp.millisecondsOfEpoch``") {
	toJson() => JsonObject {"roomId" -> tableId.roomId, "table" -> tableId.table, "timestamp" -> timestamp.millisecondsOfEpoch};
}
shared final class PlayerId(shared String id) extends StringIdentifier(id) {
	toJson() => id;
}

shared PlayerId systemPlayerId = PlayerId("");

shared RoomId parseRoomId(String json) => RoomId(json);

shared TableId parseTableId(JsonObject json) => TableId(json.getString("roomId"), json.getInteger("table"));

shared TableId? parseNullableTableId(JsonObject? json) => if (exists json) then parseTableId(json) else null; 

shared MatchId parseMatchId(JsonObject json) => MatchId(parseTableId(json), Instant(json.getInteger("timestamp")));

shared MatchId? parseNullableMatchId(JsonObject? json) => if (exists json) then parseMatchId(json) else null; 

shared PlayerId parsePlayerId(String json) => PlayerId(json);

shared PlayerId? parseNullablePlayerId(String? json) => if (exists json) then parsePlayerId(json) else null;