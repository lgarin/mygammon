import ceylon.json {
	Object,
	Array
}
import ceylon.time {

	Instant,
	now
}

shared sealed interface TableMessage of OutboundTableMessage | InboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
	shared default Integer table => tableId.table;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson()};
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeftTableMessage | CreatedMatchMessage | TableStateResponseMessage satisfies TableMessage {}

shared sealed interface InboundTableMessage of JoinTableMessage | LeaveTableMessage | TableStateRequestMessage satisfies TableMessage {
	shared formal Instant timestamp;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "tableId" -> tableId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch};
}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared PlayerInfo? playerInfo) satisfies OutboundTableMessage & RoomResponseMessage {
	shared actual Boolean success => playerInfo exists;
	toJson() => toExtendedJson {"playerInfo" -> playerInfo?.toJson()};
}
JoinedTableMessage parseJoinedTableMessage(Object json) {
	return JoinedTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), parseNullablePlayerInfo(json.getObjectOrNull("playerInfo")));
}

shared final class LeftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared actual Boolean success = true) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson {"success" -> success};
}
LeftTableMessage parseLeftTableMessage(Object json) {
	return LeftTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("success"));
}

shared final class CreatedMatchMessage(shared actual PlayerId playerId, shared MatchId matchId, shared PlayerInfo player1, shared PlayerInfo player2, shared MatchBalance balance) satisfies OutboundTableMessage {
	tableId => matchId.tableId;
	toJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "player1" -> player1.toJson(), "player2" -> player2.toJson(), "balance" -> balance.toJson()};
	shared Boolean hasPlayer(PlayerId otherPlayerId) => otherPlayerId == player1.playerId || otherPlayerId == player2.playerId;
}
CreatedMatchMessage parseCreatedMatchMessage(Object json) {
	return CreatedMatchMessage(parsePlayerId(json.getString("playerId")), parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("player1")), parsePlayerInfo(json.getObject("player2")), parseMatchBalance(json.getObject("balance")));
}

shared final class JoinTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared actual Instant timestamp = now()) satisfies InboundTableMessage {}
JoinTableMessage parseJoinTableMessage(Object json) {
	return JoinTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), Instant(json.getInteger("timestamp")));
}

shared final class LeaveTableMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared actual Instant timestamp = now()) satisfies InboundTableMessage {}
LeaveTableMessage parseLeaveTableMessage(Object json) {
	return LeaveTableMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), Instant(json.getInteger("timestamp")));
}

shared final class TableStateRequestMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared Boolean current, shared actual Instant timestamp = now()) satisfies InboundTableMessage {
	toJson() => toExtendedJson {"current" -> current};
}
TableStateRequestMessage parseTableStateRequestMessage(Object json) {
	return TableStateRequestMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), json.getBoolean("current"), Instant(json.getInteger("timestamp")));
}

shared final class TableStateResponseMessage(shared actual PlayerId playerId, shared actual TableId tableId, shared MatchState? match, shared [PlayerInfo*] playerQueue, shared actual Boolean success) satisfies OutboundTableMessage & RoomResponseMessage {
	toJson() => toExtendedJson {"match" -> match?.toJson(), "playerQueue" -> Array {for (e in playerQueue) e.toJson()}, "success" -> success};
	shared Boolean gameStarted => match?.gameStarted else false;
	shared Boolean isPlayerInQueue(PlayerId playerId) => playerQueue.any((item) => item.id == playerId.id);
	
}
TableStateResponseMessage parseTableStateResponseMessage(Object json) {
	return TableStateResponseMessage(parsePlayerId(json.getString("playerId")), parseTableId(json.getObject("tableId")), parseNullableMatchState(json.getObjectOrNull("match")), json.getArray("playerQueue").narrow<Object>().collect(parsePlayerInfo), json.getBoolean("success"));
}
