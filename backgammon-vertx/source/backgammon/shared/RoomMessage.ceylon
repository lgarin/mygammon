import ceylon.json {

	Object,
	Value,
	JsonArray=Array
}
import ceylon.time {

	Instant,
	now
}

shared sealed interface RoomMessage of InboundRoomMessage | OutboundRoomMessage | TableMessage satisfies ApplicationMessage {
	shared formal PlayerId playerId;
	shared formal RoomId roomId;
	
	shared default Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson()};
	shared actual default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
}

shared sealed interface InboundRoomMessage of EnterRoomMessage | LeaveRoomMessage | FindMatchTableMessage | FindEmptyTableMessage | RoomStateRequestMessage | PlayerStateRequestMessage satisfies RoomMessage {
	shared formal Instant timestamp;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch};
}

shared sealed interface OutboundRoomMessage of RoomActionResponseMessage | FoundMatchTableMessage | FoundEmptyTableMessage | PlayerListMessage | PlayerStateMessage satisfies RoomMessage & StatusResponseMessage {
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "success" -> success };
}

shared final class EnterRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared PlayerInfo playerInfo, shared PlayerStatistic playerStatistic, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {
	toJson() => toExtendedJson {"playerInfo" -> playerInfo.toJson(), "playerStatistic" -> playerStatistic.toJson()};
}
EnterRoomMessage parseEnterRoomMessage(Object json) {
	return EnterRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), parsePlayerInfo(json.getObject("playerInfo")), parsePlayerStatistic(json.getObject("playerStatistic")), Instant(json.getInteger("timestamp")));
}

shared final class LeaveRoomMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {}
LeaveRoomMessage parseLeaveRoomMessage(Object json) {
	return LeaveRoomMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
}

shared final class FindMatchTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {}
FindMatchTableMessage parseFindMatchTableMessage(Object json) {
	return FindMatchTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
}

shared final class FindEmptyTableMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {}
FindEmptyTableMessage parseFindEmptyTableMessage(Object json) {
	return FindEmptyTableMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
}

shared final class RoomStateRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {
	mutation => false;
}
RoomStateRequestMessage parseRoomStateRequestMessage(Object json) {
	return RoomStateRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerStateRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundRoomMessage {
	mutation => false;
}
PlayerStateRequestMessage parsePlayerStateRequestMessage(Object json) {
	return PlayerStateRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
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
	shared actual PlayerId playerId = state?.playerId else systemPlayerId;
	shared Boolean hasGame => match?.hasGame else false;
	toJson() => toExtendedJson {"state" -> state?.toJson(), "match" -> match?.toJson()};
}
PlayerStateMessage parsePlayerStateMessageMessage(Object json) {
	return PlayerStateMessage(parseRoomId(json.getString("roomId")), parseNullablePlayerState(json.getObjectOrNull("state")), parseNullableMatchState(json.getObjectOrNull("match")));
}
