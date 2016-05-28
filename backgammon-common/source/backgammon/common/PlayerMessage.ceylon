shared interface PlayerMessage {
	shared formal Player player;
}

class JoinedTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class LeaftTableMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class WaitingOpponentMessage(shared actual Player player, shared Table table) satisfies PlayerMessage {}
class JoiningGameMessage(shared actual Player player, shared Game game) satisfies PlayerMessage {}