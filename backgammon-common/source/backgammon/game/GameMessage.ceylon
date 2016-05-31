shared interface GameMessage {
	shared formal String gameId;
	shared formal String playerId;
}

shared class StartGameTurn(shared actual String gameId, shared actual String playerId) satisfies GameMessage {}