import backgammon.game {

	GameMessage
}
shared sealed interface ApplicationMessage {}

shared sealed interface PlayerMessage satisfies ApplicationMessage {
	shared formal Player player;
}

shared sealed interface TableMessage satisfies PlayerMessage {
	shared formal Table table;
}

shared final class JoinedTableMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}
shared final class LeaftTableMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}
shared final class WaitingOpponentMessage(shared actual Player player, shared actual Table table) satisfies TableMessage {}

shared sealed interface MatchMessage satisfies TableMessage {
	shared formal Match match;
	shared actual Table table => match.table;
}

shared final class JoiningMatchMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}
shared final class EndedMatchMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}

shared final class StartGameMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}
shared final class SurrenderGameMessage(shared actual Player player, shared actual Match match) satisfies MatchMessage {}

shared final class AdaptedGameMessage(shared actual Player player, shared actual Match match, shared GameMessage sourceMessage) satisfies MatchMessage {}