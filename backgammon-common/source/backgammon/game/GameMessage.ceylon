shared sealed interface GameMessage of InboundGameMessage | OutboundGameMessage {
	shared formal String gameId;
	shared formal String playerId;
}

shared interface InboundGameMessage of PlayerReadyMessage | CheckTimeoutMessage | MakeMoveMessage | UndoMovesMessage | EndTurnMessage | EndGameMessage satisfies GameMessage {}
shared interface OutboundGameMessage of InitialRollMessage | StartTurnMessage | PlayedMoveMessage | UndoneMovesMessage | InvalidMoveMessage | InvalidStateMessage | NotYourTurnMessage | GameWonMessage | GameEndedMessage satisfies GameMessage {}

shared final class InitialRollMessage(shared actual String gameId, shared actual String playerId, shared Integer roll) satisfies OutboundGameMessage {}
shared final class PlayerReadyMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class CheckTimeoutMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class StartTurnMessage(shared actual String gameId, shared actual String playerId, shared DiceRoll roll) satisfies OutboundGameMessage {}
shared final class MakeMoveMessage(shared actual String gameId, shared actual String playerId, shared GameMove move) satisfies InboundGameMessage {}
shared final class UndoMovesMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class UndoneMovesMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}
shared final class PlayedMoveMessage(shared actual String gameId, shared actual String playerId, shared GameMove move) satisfies OutboundGameMessage {}
shared final class InvalidMoveMessage(shared actual String gameId, shared actual String playerId, shared GameMove move) satisfies OutboundGameMessage {}
shared final class InvalidStateMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}
shared final class NotYourTurnMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}
shared final class EndTurnMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class GameWonMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}
shared final class EndGameMessage(shared actual String gameId, shared actual String playerId) satisfies InboundGameMessage {}
shared final class GameEndedMessage(shared actual String gameId, shared actual String playerId) satisfies OutboundGameMessage {}