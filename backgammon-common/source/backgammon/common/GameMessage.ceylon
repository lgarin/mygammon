import backgammon.game {
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
	Duration
}

shared sealed interface GameMessage of InboundGameMessage | OutboundGameMessage satisfies MatchMessage {}

shared interface InboundGameMessage of StartGameMessage | PlayerReadyMessage | CheckTimeoutMessage | MakeMoveMessage | UndoMovesMessage | EndTurnMessage | EndGameMessage | GameStateRequestMessage satisfies GameMessage {}

shared interface OutboundGameMessage of InitialRollMessage | StartTurnMessage | PlayedMoveMessage | UndoneMovesMessage | InvalidMoveMessage | DesynchronizedMessage | NotYourTurnMessage | GameWonMessage | GameEndedMessage | GameStateResponseMessage | GameActionResponseMessage satisfies GameMessage {
	shared formal CheckerColor playerColor;
	shared actual default Object toBaseJson() => Object({"playerId" -> playerId.toJson(), "matchId" -> matchId.toJson(), "playerColor" -> playerColor.name });
}

shared final class StartGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared PlayerId opponentId) satisfies InboundGameMessage {
	toJson() => toExtendedJson({"opponentId" -> opponentId.toJson()});
}
shared StartGameMessage parseStartGameMessage(Object json) {
	return StartGameMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parsePlayerId(json.getString("opponentId")));
}

shared final class InitialRollMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer diceValue, shared DiceRoll roll, shared Duration maxDuration) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"diceValue" -> diceValue, "rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds });
}
shared InitialRollMessage parseInitialRollMessage(Object json) {
	return InitialRollMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("diceValue"), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Duration(json.getInteger("maxDuration")));
}

shared final class PlayerReadyMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared PlayerReadyMessage parsePlayerReadyMessage(Object json) {
	return PlayerReadyMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

// TODO timeout should be handled differently
shared final class CheckTimeoutMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared CheckTimeoutMessage parseCheckTimeoutMessage(Object json) {
	return CheckTimeoutMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

shared final class StartTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared DiceRoll roll, shared Duration maxDuration, shared Integer maxUndo) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"rollValue1" -> roll.firstValue, "rollValue2" -> roll.secondValue, "maxDuration" -> maxDuration.milliseconds, "maxUndo" -> maxUndo });
}
shared StartTurnMessage parseStartTurnMessage(Object json) {
	return StartTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), DiceRoll(json.getInteger("rollValue1"), json.getInteger("rollValue2")), Duration(json.getInteger("maxDuration")), json.getInteger("maxUndo"));
}

shared final class MakeMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared Integer sourcePosition, shared Integer targetPosition) satisfies InboundGameMessage {
	toJson() => toExtendedJson({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition});
}
shared MakeMoveMessage parseMakeMoveMessage(Object json) {
	return MakeMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"));
}

shared final class PlayedMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer sourcePosition, shared Integer targetPosition) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition});
}
shared PlayedMoveMessage parsePlayedMoveMessage(Object json) {
	return PlayedMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"));
}

shared final class UndoMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared UndoMovesMessage parseUndoMovesMessage(Object json) {
	return UndoMovesMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

shared final class UndoneMovesMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared UndoneMovesMessage parseUndoneMovesMessage(Object json) {
	return UndoneMovesMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class InvalidMoveMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared Integer sourcePosition, shared Integer targetPosition) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"sourcePosition" -> sourcePosition, "targetPosition" -> targetPosition});
}
shared InvalidMoveMessage parseInvalidMoveMessage(Object json) {
	return InvalidMoveMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getInteger("sourcePosition"), json.getInteger("targetPosition"));
}

shared final class DesynchronizedMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameState state) satisfies OutboundGameMessage {
	toJson() => Object({"state" -> state.toJson() });
}
shared DesynchronizedMessage parseDesynchronizedMessage(Object json) {
	return DesynchronizedMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), parseGameState(json.getObject("state")));
}

shared final class NotYourTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared NotYourTurnMessage parseNotYourTurnMessage(Object json) {
	return NotYourTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class EndTurnMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared EndTurnMessage parseEndTurnMessage(Object json) {
	return EndTurnMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

shared final class GameWonMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared GameWonMessage parseGameWonMessage(Object json) {
	return GameWonMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class EndGameMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared EndGameMessage parseEndGameMessage(Object json) {
	return EndGameMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

shared final class GameEndedMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor) satisfies OutboundGameMessage {}
shared GameEndedMessage parseGameEndedMessage(Object json) {
	return GameEndedMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")));
}

shared final class GameStateRequestMessage(shared actual MatchId matchId, shared actual PlayerId playerId) satisfies InboundGameMessage {}
shared GameStateRequestMessage parseGameStateRequestMessage(Object json) {
	return GameStateRequestMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")));
}

shared final class GameStateResponseMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared GameState state) satisfies OutboundGameMessage {
	toJson() => toExtendedJson({"state" -> state.toJson()});
	
}
shared GameStateResponseMessage parseGameStateResponseMessage(Object json) {
	return GameStateResponseMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), parseGameState(json.getObject("state")));
}

shared final class GameActionResponseMessage(shared actual MatchId matchId, shared actual PlayerId playerId, shared actual CheckerColor playerColor, shared actual Boolean success) satisfies OutboundGameMessage & RoomResponseMessage {
	toJson() => toExtendedJson({"success" -> success});
}
shared GameActionResponseMessage parseGameActionResponseMessage(Object json) {
	return GameActionResponseMessage(parseMatchId(json.getObject("matchId")), parsePlayerId(json.getString("playerId")), parseCheckerColor(json.getString("playerColor")), json.getBoolean("success"));
}

shared OutboundGameMessage? parseOutboundGameMessage(String typeName, Object json) {
	if (typeName == `class InitialRollMessage`.name) {
		return parseInitialRollMessage(json);
	} else if (typeName == `class StartTurnMessage`.name) {
		return parseStartTurnMessage(json);
	} else if (typeName == `class PlayedMoveMessage`.name) {
		return parsePlayedMoveMessage(json);
	} else if (typeName == `class UndoneMovesMessage`.name) {
		return parseUndoneMovesMessage(json);
	} else if (typeName == `class InvalidMoveMessage`.name) {
		return parseInvalidMoveMessage(json);
	} else if (typeName == `class DesynchronizedMessage`.name) {
		return parseDesynchronizedMessage(json);
	} else if (typeName == `class NotYourTurnMessage`.name) {
		return parseNotYourTurnMessage(json);
	} else if (typeName == `class GameWonMessage`.name) {
		return parseGameWonMessage(json);
	} else if (typeName == `class GameEndedMessage`.name) {
		return parseGameEndedMessage(json);
	} else if (typeName == `class GameStateResponseMessage`.name) {
		return parseGameStateResponseMessage(json);
	} else if (typeName == `class GameActionResponseMessage`.name) {
		return parseGameActionResponseMessage(json);
	} else {
		return null;
	}
}

shared InboundGameMessage? parseInboundGameMessage(String typeName, Object json) {
	if (typeName == `class StartGameMessage`.name) {
		return parseStartGameMessage(json);
	} else if (typeName == `class PlayerReadyMessage`.name) {
		return parsePlayerReadyMessage(json);
	} else if (typeName == `class CheckTimeoutMessage`.name) {
		return parseCheckTimeoutMessage(json);
	} else if (typeName == `class MakeMoveMessage`.name) {
		return parseMakeMoveMessage(json);
	} else if (typeName == `class UndoMovesMessage`.name) {
		return parseUndoMovesMessage(json);
	} else if (typeName == `class EndTurnMessage`.name) {
		return parseEndTurnMessage(json);
	} else if (typeName == `class EndGameMessage`.name) {
		return parseEndGameMessage(json);
	} else if (typeName == `class GameStateRequestMessage`.name) {
		return parseGameStateRequestMessage(json);
	} else {
		return null;
	}
}