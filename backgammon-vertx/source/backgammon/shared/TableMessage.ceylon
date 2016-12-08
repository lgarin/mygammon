import ceylon.json {
	Object,
	Array
}

shared sealed interface TableMessage of OutboundTableMessage | InboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared default Integer table => tableId.table;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson()};
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeftTableMessage | CreatedMatchMessage | TableStateResponseMessage satisfies TableMessage {}
shared sealed interface InboundTableMessage of JoinTableMessage | LeaveTableMessage | TableStateRequestMessage satisfies TableMessage {}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared PlayerInfo? playerInfo) satisfies OutboundTableMessage & RoomResponseMessage {
	shared actual Boolean success => playerInfo exists;
	toJson() => toExtendedJson {"playerInfo" -> playerInfo?.toJson()};
}
shared JoinedTableMessage parseJoinedTableMessage(Object json) {
	return JoinedTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), parseNullablePlayerInfo(json.getObjectOrNull("playerInfo")));
}

shared final class LeftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared actual Boolean success = true) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson {"success" -> success};
}
shared LeftTableMessage parseLeftTableMessage(Object json) {
	return LeftTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("success"));
}

shared final class CreatedMatchMessage(shared actual PlayerId playerId, shared MatchId matchId, shared PlayerInfo player1, shared PlayerInfo player2) satisfies OutboundTableMessage {
	tableId => matchId.tableId;
	toJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson()};
	shared Boolean hasPlayer(PlayerId otherPlayerId) => otherPlayerId == player1.playerId || otherPlayerId == player2.playerId;
}
shared CreatedMatchMessage parseCreatedMatchMessage(Object json) {
	return CreatedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")));
}

shared final class JoinTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies InboundTableMessage {}

shared JoinTableMessage parseJoinTableMessage(Object json) {
	return JoinTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class LeaveTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies InboundTableMessage {}
shared LeaveTableMessage parseLeaveTableMessage(Object json) {
	return LeaveTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class TableStateRequestMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared Boolean current) satisfies InboundTableMessage {
	toJson() => toExtendedJson {"current" -> current};
}

shared TableStateRequestMessage parseTableStateRequestMessage(Object json) {
	return TableStateRequestMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("current"));
}

shared final class TableStateResponseMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared MatchState? match, shared [PlayerInfo*] playerQueue, shared actual Boolean success) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson {"match" -> match?.toJson(), "playerQueue" -> Array {for (e in playerQueue) e.toJson()}, "success" -> success};
	shared Boolean gameStarted => match?.gameStarted else false;
	
}
shared TableStateResponseMessage parseTableStateResponseMessage(Object json) {
	return TableStateResponseMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), parseNullableMatchState(json.getObjectOrNull("match")), json.getArray("playerQueue").narrow<Object>().collect(parsePlayerInfo), json.getBoolean("success"));
}

shared OutboundTableMessage? parseOutboundTableMessage(String typeName, Object json) {
	if (typeName == `class JoinedTableMessage`.name) {
		return parseJoinedTableMessage(json);
	} else if (typeName == `class LeftTableMessage`.name) {
		return parseLeftTableMessage(json);
	} else if (typeName == `class CreatedMatchMessage`.name) {
		return parseCreatedMatchMessage(json);
	} else if (typeName == `class TableStateResponseMessage`.name) {
		return parseTableStateResponseMessage(json);
	} else {
		return null;
	}
}

shared InboundTableMessage? parseInboundTableMessage(String typeName, Object json) {
	if (typeName == `class LeaveTableMessage`.name) {
		return parseLeaveTableMessage(json);
	} else if (typeName == `class JoinTableMessage`.name) {
		return parseJoinTableMessage(json);
	} else if (typeName == `class TableStateRequestMessage`.name) {
		return parseTableStateRequestMessage(json);
	} else {
		return null;
	}
}