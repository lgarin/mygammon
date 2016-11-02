import ceylon.json {
	Object
}

shared sealed interface TableMessage of OutboundTableMessage | InboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared default Integer table => tableId.table;
	shared default actual Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson()});
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeftTableMessage | CreatedMatchMessage | TableStateResponseMessage satisfies TableMessage {}
shared sealed interface InboundTableMessage of LeaveTableMessage | TableStateRequestMessage satisfies TableMessage {}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared JoinedTableMessage parseJoinedTableMessage(Object json) {
	return JoinedTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class LeftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared actual Boolean success = true) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
}
shared LeftTableMessage parseLeftTableMessage(Object json) {
	return LeftTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("success"));
}

shared final class CreatedMatchMessage(shared actual PlayerId playerId, shared MatchId matchId, shared PlayerInfo player1, shared PlayerInfo player2) satisfies OutboundTableMessage {
	tableId => matchId.tableId;
	toJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson()};
}
shared CreatedMatchMessage parseCreatedMatchMessage(Object json) {
	return CreatedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")));
}

shared final class LeaveTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies InboundTableMessage {}
shared LeaveTableMessage parseLeaveTableMessage(Object json) {
	return LeaveTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class TableStateRequestMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies InboundTableMessage {}

shared TableStateRequestMessage parseTableStateRequestMessage(Object json) {
	return TableStateRequestMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class TableStateResponseMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared Boolean joined, shared MatchState? match, shared actual Boolean success) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"joined" -> joined, "match" -> match?.toJson(), "success" -> success});
	shared Boolean gameStarted => match?.gameStarted else false;
	
}
shared TableStateResponseMessage parseTableStateResponseMessage(Object json) {
	return TableStateResponseMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("joined"), parseMatchState(json.getObjectOrNull("match")), json.getBoolean("success"));
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
	} else if (typeName == `class TableStateRequestMessage`.name) {
		return parseTableStateRequestMessage(json);
	} else {
		return null;
	}
}