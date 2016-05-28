import ceylon.time {
	Instant,
	now,
	Duration
}
shared interface Game {
	shared formal Duration remainingJoinTime;
	
	shared formal Player player1;
	shared formal Player player2;
	shared formal Table table;
}

class GameImpl(shared actual PlayerImpl player1, shared actual PlayerImpl player2, shared actual TableImpl table) satisfies Game {
	
	shared Instant creationTime = now();
	
	shared actual Duration remainingJoinTime => Duration(creationTime.durationTo(now()).milliseconds - world.maximumGameJoinTime.milliseconds);
	
	shared Boolean removePlayer(PlayerImpl player) {
		if (player === player1) {
			return table.removeGame(this);
		} else if (player === player2) {
			return table.removeGame(this);
		} else {
			return false;
		}
	}
	
}