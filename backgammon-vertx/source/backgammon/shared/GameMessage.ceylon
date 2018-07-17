import backgammon.shared.game {
	DiceRoll,
	CheckerColor,
	GameState,
	parseCheckerColor,
	parseGameState
}

import ceylon.json {
	Object
}
import ceylon.time {
	Duration,
	Instant,
	now
}

shared sealed interface GameMessage of InboundGameMessage | OutboundGameMessage | GameEventMessage satisfies MatchMessage {}

shared sealed interface InboundGameMessage of StartGameMessage | PlayerBeginMessage | MakeMoveMessage | UndoMovesMessage | EndTurnMessage | TakeTurnMessage | ControlRollMessage | EndGameMessage | GameStateRequestMessage satisfies GameMessage {
	shared formal Instant timestamp;
	shared default actual Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch};
}

shared sealed interface OutboundGameMessage of InitialRollMessage | PlayerReadyMessage | StartTurnMessage | PlayedMoveMessage | UndoneMovesMessage | InvalidMoveMessage | InvalidRollMessage | TurnTimedOutMessage | DesynchronizedMessage | NotYourTurnMessage | GameStateResponseMessage | GameActionResponseMessage satisfies GameMessage {
	shared formal CheckerColor playerColor;
	shared actual default Object toBaseJson() => Object {"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "playerColor" -> playerColor.name };
}

shared final class StartGameMessage(shared actual MatchId matchId, shared PlayerInfo playerInfo, shared PlayerId player1Id, shared PlayerId player2Id, shared actual Instant timestamp = now()) satisfies InboundGameMessage {
	shared actual PlayerId playerId = PlayerId(playerInfo.id);
	toJson() => toExtendedJson {"playerInfo" -> playerInfo.toJson(), "player1Id" -> player1Id.toJson(), "player2Id" -> player2Id.toJson()};
}
StartGameMessage parseStartGameMessage(Object json) {
	return StartGameMessage(parseMatchId(json.getObject("matchId")), parsePlayerInfo(json.getObject("playerInfo")), parsePlayerId(json.getString("player1Id")), parsePlayerId(json.getString("player2Id")), Instant(json.getInteger("timestamp")));
}

shared final class InitialRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer diceValue, shared DiceRoll roll, shared Duration maxDuration) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"diceValue" -> diceValue, "rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds};
}
InitialRollMessage parseInitialRollMessage(Object json) {
	return InitialRollMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("diceValue"), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Duration(json.getInteger("maxDuration")));
}

shared final class PlayerBeginMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {}
PlayerBeginMessage parsePlayerBeginMessage(Object json) {
	return PlayerBeginMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class PlayerReadyMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer jokerCount) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"jokerCount" -> jokerCount};
}
PlayerReadyMessage parsePlayerReadyMessage(Object json) {
	return PlayerReadyMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("jokerCount"));
}

shared final class StartTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared DiceRoll roll, shared Duration maxDuration, shared Integer maxUndo, shared GameJoker? joker = null) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds, "maxUndo" -> maxUndo, "joker" -> joker?.name };
}
StartTurnMessage parseStartTurnMessage(Object json) {
	return StartTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Duration(json.getInteger("maxDuration")), json.getInteger("maxUndo"), parseNullableGameJoker(json.getStringOrNull("joker")));
}

shared final class MakeMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared Integer sourcePosition, shared Integer targetPosition, shared actual Instant timestamp = now()) satisfies InboundGameMessage {
	toJson() => toExtendedJson {"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition};
}
MakeMoveMessage parseMakeMoveMessage(Object json) {
	return MakeMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"), Instant(json.getInteger("timestamp")));
}

shared final class PlayedMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer sourcePosition, shared Integer targetPosition) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition};
}
PlayedMoveMessage parsePlayedMoveMessage(Object json) {
	return PlayedMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"));
}

shared final class UndoMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {}
UndoMovesMessage parseUndoMovesMessage(Object json) {
	return UndoMovesMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class UndoneMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
UndoneMovesMessage parseUndoneMovesMessage(Object json) {
	return UndoneMovesMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class InvalidMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer sourcePosition, shared Integer targetPosition) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition};
}
InvalidMoveMessage parseInvalidMoveMessage(Object json) {
	return InvalidMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"));
}

shared final class InvalidRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared DiceRoll roll) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue};
	
}
InvalidRollMessage parseInvalidRollMessage(Object json) {
	return InvalidRollMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")));
}

shared final class TurnTimedOutMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
TurnTimedOutMessage parseTurnTimedOutMessage(Object json) {
	return TurnTimedOutMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class DesynchronizedMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameState state) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"state" -> state.toJson()};
}
DesynchronizedMessage parseDesynchronizedMessage(Object json) {
	return DesynchronizedMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), parseGameState(json.getObject("state")));
}

shared final class NotYourTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
NotYourTurnMessage parseNotYourTurnMessage(Object json) {
	return NotYourTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class TakeTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {}
TakeTurnMessage parseTakeTurnMessage(Object json) {
	return TakeTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class ControlRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared DiceRoll roll, shared actual Instant timestamp = now()) satisfies InboundGameMessage {
	toJson() => toExtendedJson {"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue};
}
ControlRollMessage parseControlRollMessage(Object json) {
	return ControlRollMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Instant(json.getInteger("timestamp")));
}

shared final class EndTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {}
EndTurnMessage parseEndTurnMessage(Object json) {
	return EndTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class EndGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {}
EndGameMessage parseEndGameMessage(Object json) {
	return EndGameMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class GameStateRequestMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual Instant timestamp = now()) satisfies InboundGameMessage {
	mutation => false;
}
GameStateRequestMessage parseGameStateRequestMessage(Object json) {
	return GameStateRequestMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), Instant(json.getInteger("timestamp")));
}

shared final class GameStateResponseMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameState state) satisfies OutboundGameMessage {
	toJson() => toExtendedJson {"state" -> state.toJson()};
	
}
GameStateResponseMessage parseGameStateResponseMessage(Object json) {
	return GameStateResponseMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), parseGameState(json.getObject("state")));
}

shared final class GameActionResponseMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared actual Boolean success) satisfies OutboundGameMessage & StatusResponseMessage {
	toJson() => toExtendedJson {"success" -> success};
}
GameActionResponseMessage parseGameActionResponseMessage(Object json) {
	return GameActionResponseMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getBoolean("success"));
}

