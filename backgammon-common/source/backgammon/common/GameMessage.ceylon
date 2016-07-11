import backgammon.game {

	DiceRoll,
	GameMove,
	CheckerColor,
	GameState
}
import ceylon.time {

	Duration
}
import ceylon.json {

	Object,
	Value
}

shared sealed interface GameMessage of InboundGameMessage | OutboundGameMessage satisfies MatchMessage {}

shared interface InboundGameMessage of StartGameMessage | PlayerReadyMessage | CheckTimeoutMessage | MakeMoveMessage | UndoMovesMessage | EndTurnMessage | EndGameMessage satisfies GameMessage {}
shared interface OutboundGameMessage of InitialRollMessage | StartTurnMessage | PlayedMoveMessage | UndoneMovesMessage | InvalidMoveMessage | DesynchronizedMessage | NotYourTurnMessage | GameWonMessage | GameEndedMessage satisfies GameMessage {
	shared formal CheckerColor playerColor;
	function toBaseJson() => Object({"matchId" -> matchId.toJson(), "playerId" -> playerId.toJson(), "playerColor" -> playerColor.name });
	shared default Object toJson() => toBaseJson();
	shared Object toExtendedJson({<String->Value>*} entries) {
		value result = toBaseJson();
		result.putAll(entries);
		return result;
	}
}

shared final class StartGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared PlayerId opponentId) satisfies InboundGameMessage {}
shared final class InitialRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer diceValue, shared DiceRoll roll, shared Duration maxDuration) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"diceValue" -> diceValue, "rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds });
}
shared final class PlayerReadyMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class CheckTimeoutMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class StartTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared DiceRoll roll, shared Duration maxDuration, shared Integer maxUndo) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds, "maxUndo" -> maxUndo });
}
shared final class MakeMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared GameMove move) satisfies InboundGameMessage {}
shared final class UndoMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class UndoneMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared final class PlayedMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameMove move) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"move" -> move.toJson() });
}
shared final class InvalidMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameMove move) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"move" -> move.toJson() });
}
shared final class DesynchronizedMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameState state) satisfies OutboundGameMessage {
	toJson() => Object({"state" -> state.toJson() });
}
shared final class NotYourTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared final class EndTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class GameWonMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared final class EndGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared final class GameEndedMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}