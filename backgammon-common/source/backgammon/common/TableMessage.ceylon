shared sealed interface TableMessage of OutboundTableMessage | MatchMessage satisfies RoomMessage  {
	shared formal TableId tableId;
	shared actual RoomId roomId => RoomId(tableId.roomId);
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeaftTableMessage | WaitingOpponentMessage satisfies TableMessage {}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared final class LeaftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared final class WaitingOpponentMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
