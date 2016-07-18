import ceylon.json {
	Object
}
shared sealed interface TableMessage of OutboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared default actual Object toJson() => Object({"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson()});
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeaftTableMessage | WaitingOpponentMessage satisfies TableMessage {}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared JoinedTableMessage parseJoinedTableMessage(Object json) {
	return JoinedTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class LeaftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared LeaftTableMessage parseLeaftTableMessage(Object json) {
	return LeaftTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared final class WaitingOpponentMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared WaitingOpponentMessage parseWaitingOpponentMessage(Object json) {
	return WaitingOpponentMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")));
}

shared TableMessage? parseTableMessage(String typeName, Object json) {
	if (typeName == `class JoinedTableMessage`.name) {
		return parseWaitingOpponentMessage(json);
	} else if (typeName == `class LeaftTableMessage`.name) {
		return parseLeaftTableMessage(json);
	} else if (typeName == `class WaitingOpponentMessage`.name) {
		return parseWaitingOpponentMessage(json);
	} else {
		return parseMatchMessage(typeName, json);
	}
}