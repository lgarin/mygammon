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
	value initialPositionCounts = [ 1 -> 2, 12 -> 5, 17 -> 3, 19 -> 5 ];
	value checkerCount = sum(initialPositionCounts.map((Integer->Integer element) => element.item)); 
	
	for (value element in initialPositionCounts) {
		assert (board.putNewCheckers(element.key - board.whiteHomePosition, white, element.item));
		assert (board.putNewCheckers(board.blackHomePosition - element.key, black, element.item));
	}

	shared variable String? currentPlayerId = null;
	shared variable DiceRoll? currentRoll = null;
	
	variable Boolean player1Ready = false;
	variable Boolean player2Ready = false;
	variable Instant nextTimeout = Instant(0);
	
	function initialPlayerId(DiceRoll diceRoll) {
		if (diceRoll.firstValue < diceRoll.secondValue) {
			return player1Id;
		} else if (diceRoll.firstValue < diceRoll.secondValue) {
			return player2Id;
		} else {
			return null;
		}
	}
	
	shared Boolean initialRoll(DiceRoll roll, Duration maxDuration) {
		if (currentPlayerId exists) {
			return false;
		}
		
		player1Ready = false;
		player2Ready = false;
		currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean isCurrentPlayer(String playerId) => currentPlayerId?.equals(playerId) else false;

	function playerColor(String? playerId) {
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
	
	function isLegalCheckerMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (!board.isInRange(source) || !board.isInRange(target)) {
			return false;
		} else if (board.directionSign(color) * target - source <= 0) {
			return false;
		} else if (board.hasCheckerInGraveyard(color) && board.homePosition(color) != source) {
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
		if (!isCurrentPlayer(playerId)) {
			return false;
		}
		currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean hasAvailableMove(String playerId) {
		return !computeAvailableMoves(playerId).empty;
	}
	
	shared {GameMove*} computeAvailableMoves(String playerId) {
		if (isCurrentPlayer(playerId), exists color = playerColor(playerId), exists roll = currentRoll, exists maxValue = roll.maxValue) {
			value targetRangeLength = maxValue * board.directionSign(color);
			value sourcePositionRange = board.positionRange(color);
			return {
				for (source in sourcePositionRange)
					for (target in source:targetRangeLength) 
						if (isLegalCheckerMove(color, roll, source, target))
							GameMove(source, target, maxValue, board.countCheckers(target, color.oppositeColor) > 0) 
			};
		} else {
			return {}; 
		}
	}
	
	shared Boolean isLegalMove(String playerId, Integer source, Integer target) {
		if (!isCurrentPlayer(playerId)) {
			return false;
		}
		
		if (exists color = playerColor(playerId), exists roll = currentRoll) {
			return isLegalCheckerMove(color, roll, source, target);
		} else {
			return false;
		}
	}
	
	function useRollValue(String playerId, Integer source, Integer target) {
		if (exists roll = currentRoll) {
			return roll.useValueAtLeast(board.distance(source, target));
		}
		return null;
	}
	
	function hitChecker(String playerId, Integer source, Integer target) {
		if (exists color = playerColor(playerId), board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
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
		if (now > nextTimeout) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean hasWon(String playerId) {
		if (exists color = playerColor(playerId)) {
			return board.countCheckers(board.homePosition(color), color) == checkerCount;
		} else {
			return false;
		}
	}
	
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
	
	shared Boolean begin(String playerId) {
		if (currentPlayerId exists) {
			return false;
		} else if (!player1Ready && playerId == player1Id) {
			player1Ready = true;
		} else if (!player2Ready && playerId == player2Id) {
			player2Ready = true;
		} else {
			return false;
		}
		
		if (player1Ready && player2Ready, exists roll = currentRoll) {
			currentPlayerId = initialPlayerId(roll);
		}
		return true;
	}
	
	shared Boolean end() {
		if (currentRoll exists) {
			currentPlayerId = null;
			currentRoll = null;
			return true;
		}
		return false;
	}
}