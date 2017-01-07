import ceylon.json {

	Object,
	Value,
	JsonArray=Array
}
import ceylon.language.meta {

	type
}

shared sealed interface RoomMessage of InboundRoomMessage | OutboundRoomMessage | TableMessage {
	shared formal PlayerId playerId;
	shared formal RoomId roomId;
	
	shared default Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson()};
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
	
	string => toJson().string;
}

shared sealed interface InboundRoomMessage of EnterRoomMessage | LeaveRoomMessage | FindMatchTableMessage | FindEmptyTableMessage | RoomStateRequestMessage | PlayerStateRequestMessage satisfies RoomMessage {}

shared sealed interface RoomResponseMessage {
	shared formal Boolean success;
}

shared sealed interface OutboundRoomMessage of RoomActionResponseMessage | FoundMatchTableMessage | FoundEmptyTableMessage | PlayerListMessage | PlayerStateMessage satisfies RoomMessage & RoomResponseMessage {
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "success" -> success };
}

shared final class EnterRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared PlayerInfo playerInfo) satisfies InboundRoomMessage {
	toJson() => toExtendedJson {"playerInfo" -> playerInfo.toJson()};
}
EnterRoomMessage parseEnterRoomMessage(Object json) {
	return EnterRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), parsePlayerInfo(json.getObject("playerInfo")));
}

shared final class LeaveRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
LeaveRoomMessage parseLeaveRoomMessage(Object json) {
	return LeaveRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class FindMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
FindMatchTableMessage parseFindMatchTableMessage(Object json) {
	return FindMatchTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class FindEmptyTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
FindEmptyTableMessage parseFindEmptyTableMessage(Object json) {
	return FindEmptyTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class RoomStateRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
RoomStateRequestMessage parseRoomStateRequestMessage(Object json) {
	return RoomStateRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class PlayerStateRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId) satisfies InboundRoomMessage {}
PlayerStateRequestMessage parsePlayerStateRequestMessage(Object json) {
	return PlayerStateRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")));
}

shared final class RoomActionResponseMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Boolean success) satisfies OutboundRoomMessage {}
RoomActionResponseMessage parseRoomActionResponseMessage(Object json) {
	return RoomActionResponseMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getBoolean("success"));
}

shared final class FoundMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer? table) satisfies OutboundRoomMessage {
	shared actual Boolean success => table exists;
	toJson() => toExtendedJson {"table" -> table};
}
FoundMatchTableMessage parseFoundMatchTableMessage(Object json) {
	return FoundMatchTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getIntegerOrNull("table"));
}

shared final class FoundEmptyTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer? table) satisfies OutboundRoomMessage {
	shared actual Boolean success => table exists;
	toJson() => toExtendedJson {"table" -> table};
	shared TableId? tableId => if (exists table) then TableId(roomId.roomId, table) else null;
}
FoundEmptyTableMessage parseFoundEmptyTableMessage(Object json) {
	return FoundEmptyTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getIntegerOrNull("table"));
}

shared final class PlayerListMessage(shared actual RoomId roomId, shared [PlayerState*] newPlayers = [], shared [PlayerState*] oldPlayers = [], shared [PlayerState*] updatedPlayers = []) satisfies OutboundRoomMessage {
	shared actual Boolean success = !newPlayers.empty || !oldPlayers.empty || !updatedPlayers.empty;
	shared actual PlayerId playerId = systemPlayerId;
	toJson() => toExtendedJson {"newPlayers" -> JsonArray {for (e in newPlayers) e.toJson()}, "oldPlayers" -> JsonArray {for (e in oldPlayers) e.toJson()}, "updatedPlayers" -> JsonArray {for (e in updatedPlayers) e.toJson()} };
}
PlayerListMessage parsePlayerListMessageMessage(Object json) {
	return PlayerListMessage(parseRoomId(json.getString("roomId")), json.getArray("newPlayers").narrow<Object>().collect(parsePlayerState), json.getArray("oldPlayers").narrow<Object>().collect(parsePlayerState), json.getArray("updatedPlayers").narrow<Object>().collect(parsePlayerState));
}

shared final class PlayerStateMessage(shared actual RoomId roomId, shared PlayerState? state, shared MatchState? match) satisfies OutboundRoomMessage {
	shared actual Boolean success = state exists;
	shared actual PlayerId playerId = systemPlayerId;
	shared Boolean hasGame => match?.hasGame else false;
	toJson() => toExtendedJson {"state" -> state?.toJson(), "match" -> match?.toJson()};
}
PlayerStateMessage parsePlayerStateMessageMessage(Object json) {
	return PlayerStateMessage(parseRoomId(json.getString("roomId")), parseNullablePlayerState(json.getObjectOrNull("state")), parseNullableMatchState(json.getObjectOrNull("match")));
}

shared Object formatRoomMessage(RoomMessage message) {
	return Object({type(message).declaration.name -> message.toJson()});
}

shared InboundRoomMessage? parseInboundRoomMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class EnterRoomMessage`.name) {
			return parseEnterRoomMessage(json.getObject(typeName));
		} else if (typeName == `class LeaveRoomMessage`.name) {
			return parseLeaveRoomMessage(json.getObject(typeName));
		} else if (typeName == `class FindMatchTableMessage`.name) {
			return parseFindMatchTableMessage(json.getObject(typeName));
		} else if (typeName == `class FindEmptyTableMessage`.name) {
			return parseFindEmptyTableMessage(json.getObject(typeName));
		} else if (typeName == `class RoomStateRequestMessage`.name) {
			return parseRoomStateRequestMessage(json.getObject(typeName));
		} else if (typeName == `class PlayerStateRequestMessage`.name) {
			return parsePlayerStateRequestMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}

shared OutboundRoomMessage? parseOutboundRoomMessage(Object json) {
	if (exists typeName = json.keys.first) {
		if (typeName == `class RoomActionResponseMessage`.name) {
			return parseRoomActionResponseMessage(json.getObject(typeName));
		} else if (typeName == `class FoundMatchTableMessage`.name) {
			return parseFoundMatchTableMessage(json.getObject(typeName));
		} else if (typeName == `class FoundEmptyTableMessage`.name) {
			return parseFoundEmptyTableMessage(json.getObject(typeName));
		} else if (typeName == `class PlayerListMessage`.name) {
			return parsePlayerListMessageMessage(json.getObject(typeName));
		} else if (typeName == `class PlayerStateMessage`.name) {
			return parsePlayerStateMessageMessage(json.getObject(typeName));
		} else {
			return null;
		}
	} else {
		return null;
	}
}