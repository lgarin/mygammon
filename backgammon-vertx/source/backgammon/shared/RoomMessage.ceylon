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
	
	string => toJson().string;
}

shared sealed interface InboundRoomMessage of EnterRoomMessage | LeaveRoomMessage | FindMatchTableMessage satisfies RoomMessage {}

shared sealed interface RoomResponseMessage {
	shared formal Boolean success;
}

shared sealed interface OutboundRoomMessage of EnteredRoomMessage | LeftRoomMessage | FoundMatchTableMessage satisfies RoomMessage & RoomResponseMessage {
	shared default actual Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "success" -> success });
}

shared final class EnterRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared PlayerInfo playerInfo) satisfies InboundRoomMessage {
	toJson() => toExtendedJson({"playerInfo" -> playerInfo.toJson()});
}
shared EnterRoomMessage parseEnterRoomMessage(Object json) {
	return EnterRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), parsePlayerInfo(json.getObject("playerInfo")));
}

shared final class LeaveRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}

shared final class FindMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
shared FindMatchTableMessage parseFindMatchTableMessage(Object json) {
	return FindMatchTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class EnteredRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}
shared EnteredRoomMessage parseEnteredRoomMessage(Object json) {
	return EnteredRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getBoolean("success"));
}

shared final class LeftRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}

shared final class FoundMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer? table) satisfies OutboundRoomMessage {
	shared actual Boolean success => table exists;
	toJson() => toExtendedJson({"table" -> table});
}
shared FoundMatchTableMessage parseFoundMatchTableMessage(Object json) {
	return FoundMatchTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getIntegerOrNull("table"));
}

shared Object formatRoomMessage(RoomMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared InboundRoomMessage? parseInboundRoomMessage(String typeName, Object json) {
	if (typeName == `class EnterRoomMessage`.name) {
		return parseEnterRoomMessage(json);
	} else if (typeName == `class FindMatchTableMessage`.name) {
		return parseFindMatchTableMessage(json);
	} else {
		return null;
	}
}

shared OutboundRoomMessage? parseOutboundRoomMessage(String typeName, Object json) {
	if (typeName == `class EnteredRoomMessage`.name) {
		return parseEnteredRoomMessage(json);
	} else if (typeName == `class FoundMatchTableMessage`.name) {
		return parseFoundMatchTableMessage(json);
	} else {
		return null;
	}
}