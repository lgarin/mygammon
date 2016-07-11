import ceylon.json {

	Object,
	Value
}
shared sealed interface RoomMessage of InboundRoomMessage | OutboundRoomMessage | TableMessage {
	shared formal PlayerId playerId;
	shared formal RoomId roomId;
}

shared sealed interface InboundRoomMessage of EnterRoomMessage | LeaveRoomMessage | FindMatchTableMessage satisfies RoomMessage {}

shared final class EnterRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared PlayerInfo playerInfo) satisfies InboundRoomMessage {}
shared final class LeaveRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
shared final class FindMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}

shared sealed interface OutboundRoomMessage of EnteredRoomMessage | LeaftRoomMessage | FoundMatchTableMessage satisfies RoomMessage {
	shared formal Boolean success;
	function toBaseJson() => Object({"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "success" -> success });
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
}

shared final class EnteredRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}
shared final class LeaftRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}
shared final class FoundMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared TableId? tableId) satisfies OutboundRoomMessage {
	shared actual Boolean success => tableId exists;
	toJson() => toExtendedJson({"tableId" -> tableId?.toJson()});
}

