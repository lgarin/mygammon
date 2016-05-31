import ceylon.time {
	Instant,
	now
}

shared interface Game {
	shared formal String player1Id;
	shared formal String player2Id;
	
	shared formal Boolean initialRoll(DiceRoll diceRoll);
}

class GameImpl(shared actual String player1Id, shared actual String player2Id, String gameId, Anything(GameMessage) messageListener) satisfies Game {

	variable String? currentPlayerId = null;
	
	variable Instant turnStart = Instant(0);
	
	String? initialPlayerId(DiceRoll diceRoll) {
		if (diceRoll.firstValue < diceRoll.secondValue) {
			return player1Id;
		} else if (diceRoll.firstValue < diceRoll.secondValue) {
			return player2Id;
		} else {
			return null;
		}
	}
	
	shared actual Boolean initialRoll(DiceRoll diceRoll) {
		if (currentPlayerId exists) {
			return false;
		}  else if (exists playerId = initialPlayerId(diceRoll)) {
			currentPlayerId = playerId;
			messageListener(StartGameTurn(gameId, playerId));
			turnStart = now();
			return true;
		} else {
			return false;
		}
	}
}

shared Game makeGame(String player1Id, String player2Id, String gameId, Anything(GameMessage) messageListener) => GameImpl(player1Id, player2Id, gameId, messageListener);