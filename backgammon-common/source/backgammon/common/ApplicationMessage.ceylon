shared interface ApplicationMessage {}

shared interface PlayerMessage satisfies ApplicationMessage {
	shared formal Player player;
}

shared class JoinedTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
shared class LeaftTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
shared class WaitingOpponentMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
shared class JoiningMatchMessage(shared actual Player player, shared Match match) satisfies PlayerMessage {}
shared class EndedMatchMessage(shared actual Player player, shared Match match) satisfies PlayerMessage {}

shared interface GameMessage satisfies ApplicationMessage {
	shared formal Game game;
}

shared class StartGameMessage(shared actual Game game) satisfies GameMessage {}
shared class SurrenderGameMessage(shared actual Game game, shared Player player) satisfies GameMessage {}
shared class StartGameTurn(shared actual Game game, shared Player player) satisfies GameMessage {}
