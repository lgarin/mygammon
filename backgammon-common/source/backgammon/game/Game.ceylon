import ceylon.time {
	Instant,
	now,
	Duration
}
import ceylon.collection {

	ArrayList
}


shared class Game(shared String player1Id, shared String player2Id, String gameId) {

	value board = GameBoard();
	value currentMoves = ArrayList<GameMove>();
	
	board.putNewCheckers(24, black, 2);
	board.putNewCheckers(13, black, 5);
	board.putNewCheckers(8, black, 3);
	board.putNewCheckers(6, black, 5);
	
	board.putNewCheckers(1, white, 2);
	board.putNewCheckers(12, white, 5);
	board.putNewCheckers(17, white, 3);
	board.putNewCheckers(19, white, 5);

	shared variable String? currentPlayerId = null;
	shared variable DiceRoll? currentRoll = null;
	
	variable Boolean player1Ready = false;
	variable Boolean player2Ready = false;
	variable Instant nextTimeout = Instant(0);
	
	String? initialPlayerId(DiceRoll diceRoll) {
		if (diceRoll.firstValue < diceRoll.secondValue) {
			return player1Id;
		} else if (diceRoll.firstValue < diceRoll.secondValue) {
			return player2Id;
		} else {
			return null;
		}
	}
	
	shared Boolean initialRoll(DiceRoll roll, Duration maxDuration) {
		currentRoll = roll;
		player1Ready = false;
		player2Ready = false;
		nextTimeout = now().plus(maxDuration);
		if (currentPlayerId exists) {
			return false;
		}  else if (exists playerId = initialPlayerId(roll)) {
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
	
	CheckerColor? playerColor(String? playerId) {
		if (!exists playerId) {
			return null;
		} else if (playerId == player1Id) {
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
	
	shared Boolean beginTurn(String playerId, DiceRoll roll, Duration maxDuration) {
		currentPlayerId = playerId;
		currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean isLegalMove(String playerId, Integer source, Integer target) {
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
	
	Integer? useRollValue(String playerId, Integer source, Integer target) {
		if (exists roll = currentRoll) {
			return roll.useValueAtLeast(board.distance(source, target));
		}
		return null;
	}
	
	CheckerColor? hitChecker(String playerId, Integer source, Integer target) {
		if (exists color = playerColor(playerId), board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
	}
	
	// TODO
	shared Boolean submitMove(Integer source, Integer target) {
		//messageListener(MakeMoveMessage(gameId, playerId, GameMove(source, target, 0, false)));
		return true;
	}
	
	shared Boolean moveChecker(String playerId, Integer source, Integer target) {
	
		if (isLegalMove(playerId, source, target)) {
			return false;
		}
		
		value rollValue = useRollValue(playerId, source, target);
		if (!exists rollValue) {
			return false;
		}
		
		value bolt = hitChecker(playerId, source, target);
		if (exists bolt) {
			assert (board.moveChecker(target, board.graveyardPosition(bolt)));
		}
		assert (board.moveChecker(source, target));
		
		value move = GameMove(source, target, rollValue, bolt exists);
		currentMoves.push(move);
		return true;
	}
	
	shared Boolean undoTurnMoves(String playerId) {
		if (!isCurrentPlayer(playerId)) {
			return false;
		} else if (exists roll = currentRoll, exists color = playerColor(currentPlayerId)) {
			while (exists move = currentMoves.pop()) {
				currentRoll = roll.add(move.rollValue);
				assert (board.moveChecker(move.targetPosition, move.sourcePosition));
				if (move.hitBlot) {
					assert (board.moveChecker(board.graveyardPosition(color.oppositeColor), move.targetPosition));
				}
			}
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean timedOut(Instant now) {
		// TODO opponent should annouce timeout 1 second later
		if (now > nextTimeout) {
			return true;
		} else {
			return false;
		}
	}
	
	// TODO
	Boolean hasWon(String playerId) => false;
	
	shared String? switchTurn(String playerId) {
		if (!isCurrentPlayer(playerId)) {
			return null;
		} else if (playerId == player1Id) {
			currentPlayerId = player2Id;
			return currentPlayerId;
		} else if (playerId == player2Id) {
			currentPlayerId = player1Id;
			return currentPlayerId;
		} else {
			return null;
		}
	}
	
	shared Boolean endTurn(String playerId) {
		if (!isCurrentPlayer(playerId)) {
			return false;
		} else if (hasWon(playerId)) {
			currentPlayerId = null;
		}
		currentMoves.clear();
		return true;
	}
	
	shared Boolean endInitialRoll(String playerId) {
		if (currentPlayerId exists) {
			return false;
		} else if (playerId == player1Id) {
			player1Ready = true;
		} else if (playerId == player2Id) {
			player2Ready = true;
		}
		if (player1Ready && player2Ready, exists roll = currentRoll) {
			currentPlayerId = initialPlayerId(roll);
			return true;
		} else {
			return false;
		}
	}
}