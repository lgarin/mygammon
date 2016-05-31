import backgammon.game {

	GameMessage
}
shared interface ApplicationMessage {}

shared interface PlayerMessage satisfies ApplicationMessage {
	shared formal Player player;
}

shared interface TableMessage satisfies PlayerMessage {
	shared formal Table table;
}

shared class JoinedTableMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}
shared class LeaftTableMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}
shared class WaitingOpponentMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}

shared interface MatchMessage satisfies TableMessage {
	shared formal Match match;
	shared actual Table table => match.table;
}

shared class JoiningMatchMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}
shared class EndedMatchMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}

shared class StartGameMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}
shared class SurrenderGameMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}

shared class AdaptedGameMessage(shared actual Player player, shared actual Match match, shared GameMessage sourceMessage) satisfies MatchMessage {}