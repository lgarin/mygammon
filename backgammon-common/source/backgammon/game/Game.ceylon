import ceylon.time {
	Instant,
	now
}
import ceylon.language.meta.model {

	Class
}

shared interface Game {
	shared formal String player1Id;
	shared formal String player2Id;
	
	shared formal Boolean initialRoll(DiceRoll diceRoll);
}

class GameImpl(shared actual String player1Id, shared actual String player2Id, String gameId, Anything(GameMessage) messageListener) satisfies Game {

	value board = GameBoard();

	variable String? currentPlayerId = null;
	
	variable Instant turnStart = Instant(0);
	
	Class<BoardChecker,[]> checkerType(String playerId) {
		if (playerId == player1Id) {
			return `BlackChecker`;
		} else if (playerId == player2Id) {
			return `WhiteChecker`;
		} else {
			return `BoardChecker`;
		}
	}
	
	board.putNewCheckers(2, checkerType(player1Id), 24);
	board.putNewCheckers(5, checkerType(player1Id), 13);
	board.putNewCheckers(3, checkerType(player1Id), 8);
	board.putNewCheckers(5, checkerType(player1Id), 6);
	
	board.putNewCheckers(2, checkerType(player2Id), 1);
	board.putNewCheckers(5, checkerType(player2Id), 12);
	board.putNewCheckers(3, checkerType(player2Id), 17);
	board.putNewCheckers(5, checkerType(player2Id), 19);
	
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