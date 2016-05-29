import ceylon.time {
	Instant,
	now
}
shared interface Game {
	shared formal Player player1;
	shared formal Player player2;
	shared formal Table table;
}

class GameImpl(shared actual PlayerImpl player1, shared actual PlayerImpl player2, shared actual TableImpl table) satisfies Game {

	variable PlayerImpl? currentPlayer = null;
	
	shared Instant creationTime = now();
}