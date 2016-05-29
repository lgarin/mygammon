shared interface PlayerMessage {
	shared formal Player player;
}

class JoinedTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class LeaftTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class WaitingOpponentMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class JoiningMatchMessage(shared actual Player player, shared Match match) satisfies PlayerMessage {}
class StartGameMessage(shared actual Player player, shared Game game) satisfies PlayerMessage {}