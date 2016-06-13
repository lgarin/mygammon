import backgammon.game {

	DiceRoll,
	GameMove
}

shared sealed interface GameMessage of InboundGameMessage | OutboundGameMessage satisfies MatchMessage {}

shared interface InboundGameMessage of StartGameMessage | PlayerReadyMessage | CheckTimeoutMessage | MakeMoveMessage | UndoMovesMessage | EndTurnMessage | EndGameMessage satisfies GameMessage {}
shared interface OutboundGameMessage of InitialRollMessage | StartTurnMessage | PlayedMoveMessage | UndoneMovesMessage | InvalidMoveMessage | DesynchronizedMessage | NotYourTurnMessage | GameWonMessage | GameEndedMessage satisfies GameMessage {}

shared final class StartGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared PlayerId opponentId) satisfies InboundGameMessage {}
shared final class InitialRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared Integer roll) satisfies OutboundGameMessage {}
shared final class PlayerReadyMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class CheckTimeoutMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class StartTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared DiceRoll roll) satisfies OutboundGameMessage {}
shared final class MakeMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared GameMove move) satisfies InboundGameMessage {}
shared final class UndoMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class UndoneMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies OutboundGameMessage {}
shared final class PlayedMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared GameMove move) satisfies OutboundGameMessage {}
shared final class InvalidMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared GameMove move) satisfies OutboundGameMessage {}
shared final class DesynchronizedMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies OutboundGameMessage {}
shared final class NotYourTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies OutboundGameMessage {}
shared final class EndTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class GameWonMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies OutboundGameMessage {}
shared final class EndGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class GameEndedMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies OutboundGameMessage {}