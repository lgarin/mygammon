import ceylon.json {

	Object,
	Value
}
import ceylon.language.meta {

	type
}
shared sealed interface RoomMessage of InboundRoomMessage | OutboundRoomMessage | TableMessage {
	shared formal PlayerId playerId;
	shared formal RoomId roomId;
	
	shared default Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson()});
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
}

shared sealed interface InboundRoomMessage of EnterRoomMessage | LeaveRoomMessage | FindMatchTableMessage | TableStateRequestMessage satisfies RoomMessage {}


shared sealed interface OutboundRoomMessage of EnteredRoomMessage | LeaftRoomMessage | FoundMatchTableMessage | TableStateResponseMessage satisfies RoomMessage {
	shared formal Boolean success;
	shared default actual Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "success" -> success });
}

shared final class EnterRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared PlayerInfo playerInfo) satisfies InboundRoomMessage {
	toJson() => toExtendedJson({"playerInfo" -> playerInfo.toJson()});
}
shared EnterRoomMessage parseEnterRoomMessage(Object json) {
	return EnterRoomMessage(parsePlayerId(json.get("playerId")), parseRoomId(json.get("roomId")), parsePlayerInfo(json.getObject("playerInfo")));
}

shared final class LeaveRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}

shared final class FindMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
shared FindMatchTableMessage parseFindMatchTableMessage(Object json) {
	return FindMatchTableMessage(parsePlayerId(json.get("playerId")), parseRoomId(json.get("roomId")));
}

shared final class EnteredRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}
shared EnteredRoomMessage parseEnteredRoomMessage(Object json) {
	return EnteredRoomMessage(parsePlayerId(json.get("playerId")), parseRoomId(json.get("roomId")), json.getBoolean("success"));
}

shared final class LeaftRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}

shared final class FoundMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer? table) satisfies OutboundRoomMessage {
	shared actual Boolean success => table exists;
	toJson() => toExtendedJson({"table" -> table});
}
shared FoundMatchTableMessage parseFoundMatchTableMessage(Object json) {
	return FoundMatchTableMessage(parsePlayerId(json.get("playerId")), parseRoomId(json.get("roomId")), json.getIntegerOrNull("table"));
}

shared final class TableStateRequestMessage(shared actual PlayerId playerId, shared TableId tableId) satisfies InboundRoomMessage {
	shared actual RoomId roomId => RoomId(tableId.roomId);
}
shared TableStateRequestMessage parseTableStateRequestMessage(Object json) {
	return TableStateRequestMessage(parsePlayerId(json.get("playerId")), parseTableId(json.get("tableId")));
}

shared final class TableStateResponseMessage(shared actual PlayerId playerId, shared TableId tableId, shared MatchInfo? match) satisfies OutboundRoomMessage {
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared actual Boolean success => match exists;
	toJson() => toExtendedJson({"match" -> match?.toJson()});
	
}
shared TableStateResponseMessage parseTableStateResponseMessage(Object json) {
	return TableStateResponseMessage(parsePlayerId(json.get("playerId")), parseTableId(json.get("tableId")), parseMatchInfo(json.getObjectOrNull("match")));
}

shared Object formatRoomMessage(RoomMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared RoomMessage? parseRoomMessage(String typeName, Object json) {
	if (typeName == `class EnterRoomMessage`.name) {
		return parseEnterRoomMessage(json);
	} else if (typeName == `class EnteredRoomMessage`.name) {
		return parseEnteredRoomMessage(json);
	} else if (typeName == `class FindMatchTableMessage`.name) {
		return parseFindMatchTableMessage(json);
	} else if (typeName == `class FoundMatchTableMessage`.name) {
		return parseFoundMatchTableMessage(json);
	} else if (typeName == `class TableStateRequestMessage`.name) {
		return parseTableStateRequestMessage(json);
	} else if (typeName == `class TableStateResponseMessage`.name) {
		return parseTableStateResponseMessage(json);
	} else {
		return parseTableMessage(typeName, json);
	}
}