import ceylon.time {

	Instant
}
shared abstract class StringIdentifier(String id) satisfies Identifiable {
	string = id;
	
	shared actual Boolean equals(Object that) {
		return id == that.string;
	}
	
	shared actual Integer hash => id.hash;
}

shared final class RoomId(shared String roomId) extends StringIdentifier(roomId) {}
shared final class TableId(shared RoomId roomId, shared Integer index) extends StringIdentifier("``roomId``-table-``index``") {}
shared final class MatchId(shared TableId tableId, Instant creationTime) extends StringIdentifier("``tableId``-game-``creationTime.millisecondsOfEpoch``") {}
shared final class PlayerId(shared String id) extends StringIdentifier(id) {}
