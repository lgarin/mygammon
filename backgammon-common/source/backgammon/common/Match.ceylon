import ceylon.time {

	Duration,
	Instant,
	now
}
shared interface Match {
	shared formal Duration remainingJoinTime;
	
	shared formal Player player1;
	shared formal Player player2;
	shared formal Table table;
	
	shared formal Game? game;
}

class MatchImpl(shared actual PlayerImpl player1, shared actual PlayerImpl player2, shared actual TableImpl table) satisfies Match {
	
	shared actual variable Game? game = null;
	
	shared Instant creationTime = now();
	
	shared actual Duration remainingJoinTime => Duration(creationTime.durationTo(now()).milliseconds - world.maximumGameJoinTime.milliseconds);
	
	variable Boolean player1Ready = false;
	variable Boolean player2Ready = false;
	
	shared Boolean removePlayer(PlayerImpl player) {
		if (player === player1) {
			return table.removeMatch(this);
		} else if (player === player2) {
			return table.removeMatch(this);
		} else {
			return false;
		}
	}
}