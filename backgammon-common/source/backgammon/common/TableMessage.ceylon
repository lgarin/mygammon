import ceylon.json {
	Object
}
import ceylon.time {

	Duration
}
shared sealed interface TableMessage of OutboundTableMessage | InboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared default actual Object toJson() => Object({"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson()});
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeftTableMessage | WaitingOpponentMessage | CreatedMatchMessage satisfies TableMessage {}
shared sealed interface InboundTableMessage of LeaveTableMessage satisfies TableMessage {}

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

shared final class WaitingOpponentMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared WaitingOpponentMessage parseWaitingOpponentMessage(Object json) {
	return WaitingOpponentMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class CreatedMatchMessage(shared actual PlayerId playerId, shared MatchId matchId, shared PlayerInfo player1, shared PlayerInfo player2, shared Duration remainingJoinTime) satisfies OutboundTableMessage {
	tableId => matchId.tableId;
	toJson() => toExtendedJson({"player1" -> player1.toJson(), "player2" -> player2.toJson(), "remainingJoinTime" -> remainingJoinTime.milliseconds});
}
shared CreatedMatchMessage parseCreatedMatchMessage(Object json) {
	return CreatedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), Duration(json.getInteger("remainingJoinTime")));
}

shared final class LeaveTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies InboundTableMessage {}
shared LeaveTableMessage parseLeaveTableMessage(Object json) {
	return LeaveTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared OutboundTableMessage? parseOutboundTableMessage(String typeName, Object json) {
	if (typeName == `class JoinedTableMessage`.name) {
		return parseWaitingOpponentMessage(json);
	} else if (typeName == `class LeftTableMessage`.name) {
		return parseLeftTableMessage(json);
	} else if (typeName == `class WaitingOpponentMessage`.name) {
		return parseWaitingOpponentMessage(json);
	} else if (typeName == `class CreatedMatchMessage`.name) {
		return parseCreatedMatchMessage(json);
	} else {
		return null;
	}
}

shared InboundTableMessage? parseInboundTableMessage(String typeName, Object json) {
	if (typeName == `class LeaveTableMessage`.name) {
		return parseLeaveTableMessage(json);
	} else {
		return null;
	}
}