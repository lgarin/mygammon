shared sealed interface GameMessage {
	shared formal String gameId;
	shared formal String playerId;
}

shared final class StartGameTurn(shared actual String gameId, shared actual String playerId) satisfies GameMessage {}