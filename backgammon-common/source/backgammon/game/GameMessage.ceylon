shared sealed interface GameMessage {
	shared formal String gameId;
	shared formal String playerId;
}

shared interface InboundGameMessage satisfies GameMessage {}
shared interface OutboundGameMessage satisfies GameMessage {}

shared final class StartTurnMessage(shared actual String gameId, shared actual String playerId, shared DiceRoll roll) satisfies OutboundGameMessage {}
shared final class MakeMoveMessage(shared actual String gameId, shared actual String playerId, shared GameMove move) satisfies InboundGameMessage {}
shared final class PlayedMoveMessage(shared actual String gameId, shared actual String playerId, shared GameMove move) satisfies OutboundGameMessage {}
shared final class InvalidMoveMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}
shared final class TurnTimeoutMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class EndTurnMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class GameWonMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}