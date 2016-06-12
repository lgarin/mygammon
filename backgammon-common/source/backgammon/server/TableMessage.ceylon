shared sealed interface TableMessage of OutboundTableMessage | MatchMessage {
	shared formal PlayerId playerId;
	shared formal TableId tableId;
}

shared sealed interface OutboundTableMessage of JoinedTableMessage | LeaftTableMessage | WaitingOpponentMessage satisfies TableMessage {}

shared final class JoinedTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared final class LeaftTableMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
shared final class WaitingOpponentMessage(shared actual PlayerId playerId, shared actual TableId tableId) satisfies OutboundTableMessage {}
