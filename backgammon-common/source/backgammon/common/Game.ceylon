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
	
	variable Instant turnStart = Instant(0);
	
	PlayerImpl? initialPlayer(DiceRoll diceRoll) {
		if (diceRoll.firstValue < diceRoll.secondValue) {
			return player1;
		} else if (diceRoll.firstValue < diceRoll.secondValue) {
			return player2;
		} else {
			return null;
		}
	}
	
	shared Boolean initialRoll(DiceRoll diceRoll) {
		if (currentPlayer exists) {
			return false;
		}  else if (exists player = initialPlayer(diceRoll)) {
			currentPlayer = player;
			world.publish(StartGameTurn(this, player));
			turnStart = now();
			return true;
		} else {
			return false;
		}
	}
	
	
}