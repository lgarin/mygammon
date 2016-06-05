import ceylon.time {
	Instant,
	now
}

shared interface Game {
	shared formal String player1Id;
	shared formal String player2Id;
	
	shared formal Boolean initialRoll(DiceRoll diceRoll);
	shared formal Boolean isLegalMove(String playerId, Integer source, Integer target);
	shared formal Boolean moveChecker(String playerId, Integer source, Integer target);
}

class GameImpl(shared actual String player1Id, shared actual String player2Id, String gameId, Anything(GameMessage) messageListener) satisfies Game {

	value board = GameBoard();
	
	board.putNewCheckers(24, black, 2);
	board.putNewCheckers(13, black, 5);
	board.putNewCheckers(8, black, 3);
	board.putNewCheckers(6, black, 5);
	
	board.putNewCheckers(1, white, 2);
	board.putNewCheckers(12, white, 5);
	board.putNewCheckers(17, white, 3);
	board.putNewCheckers(19, white, 5);

	variable String? currentPlayerId = null;
	variable DiceRoll? currentRoll = null;
	
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
			messageListener(StartTurnMessage(gameId, playerId, diceRoll));
			turnStart = now();
			return true;
		} else {
			return false;
		}
	}
	
	Boolean isCurrentPlayer(String playerId) => currentPlayerId?.equals(playerId) else false;
	
	Boolean isCorrectDirection(String playerId, Integer source, Integer target) {
		if (playerId == player1Id) {
			return source > target;
		} else if (playerId == player2Id){
			return target > source;
		} else {
			return false;
		}
	}
	
	CheckerColor? playerColor(String playerId) {
		if (playerId == player1Id) {
			return black;
		} else if (playerId == player2Id) {
			return white;
		} else {
			return null;
		}
	}
	
	Boolean isLegalCheckerMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (board.hasCheckerInGraveyard(color) && board.homePosition(color) != source) {
			return false;
		} else if (board.countCheckers(source, color) == 0) {
			return false;
		} else if (board.countCheckers(target, color.oppositeColor) > 1) {
			return false;
		} else if (board.hasCheckersOutsideHomeArea(color)) {
			if (board.homePosition(color) == target) {
				return false;
			} else {
				return roll.hasValue(board.distance(source, target));
			}
		} else if (exists maxValue = roll.maxValue) {
			return maxValue >= board.distance(source, target);
		} else {
			return false;
		}
	}
	
	shared actual Boolean isLegalMove(String playerId, Integer source, Integer target) {
		if (!isCurrentPlayer(playerId)) {
			return false;
		} else if (!isCorrectDirection(playerId, source, target)) {
			return false;
		}
		
		if (exists color = playerColor(playerId), exists roll = currentRoll) {
			return isLegalCheckerMove(color, roll, source, target);
		} else {
			return false;
		}
	}
	
	Boolean useRollValue(String playerId, Integer source, Integer target) {
		if (exists roll = currentRoll) {
			return roll.useValueAtLeast(board.distance(source, target));
		}
		return false;
	}
	
	CheckerColor? hitChecker(String playerId, Integer source, Integer target) {
		if (exists color = playerColor(playerId), board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
	}

	shared actual Boolean moveChecker(String playerId, Integer source, Integer target) {
		if (isLegalMove(playerId, source, target)) {
			return false;
		}
		
		if (!useRollValue(playerId, source, target)) {
			return false;
		}
		
		value bolt = hitChecker(playerId, source, target);
		if (exists bolt) {
			board.moveChecker(target, board.graveyardPosition(bolt));
		}
		board.moveChecker(source, target);
		
		messageListener(PlayedMoveMessage(gameId, playerId, GameMove(source, target, bolt exists)));
		return true;
	}
}

shared Game makeGame(String player1Id, String player2Id, String gameId, Anything(GameMessage) messageListener) => GameImpl(player1Id, player2Id, gameId, messageListener);