import ceylon.time {
	Instant,
	now,
	Duration
}
import ceylon.collection {

	ArrayList
}


shared class Game() {

	value board = GameBoard();
	value currentMoves = ArrayList<GameMove>();
	value initialPositionCounts = [ 1 -> 2, 12 -> 5, 17 -> 3, 19 -> 5 ];
	value checkerCount = sum(initialPositionCounts.map((Integer->Integer element) => element.item)); 
	
	for (value element in initialPositionCounts) {
		assert (board.putNewCheckers(element.key - board.whiteHomePosition, white, element.item));
		assert (board.putNewCheckers(board.blackHomePosition - element.key, black, element.item));
	}

	shared variable CheckerColor? currentColor = null;
	shared variable DiceRoll? currentRoll = null;
	
	variable Integer remainingUndo = 0;
	variable Boolean blackReady = false;
	variable Boolean whiteReady = false;
	variable Instant nextTimeout = Instant(0);
	
	function initialColor(DiceRoll diceRoll) {
		if (diceRoll.getValue(black) > diceRoll.getValue(white)) {
			return black;
		} else if (diceRoll.getValue(black) < diceRoll.getValue(white)) {
			return white;
		} else {
			return null;
		}
	}
	
	shared Boolean initialRoll(DiceRoll roll, Duration maxDuration) {
		if (currentColor exists) {
			return false;
		}
		
		blackReady = false;
		whiteReady = false;
		currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean isCurrentColor(CheckerColor color) => currentColor?.equals(color) else false;
	
	shared Boolean mustRollDice(CheckerColor playerColor) {
		if (currentColor exists || currentRoll is Null) {
			return false;
		} else if (!blackReady && playerColor == black) {
			return true;
		} else if (!whiteReady && playerColor == white) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean mustMakeMove(CheckerColor playerColor) {
		if (exists color = currentColor) {
			return color == playerColor; 
		} else {
			return false;
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
	
	shared Boolean beginTurn(CheckerColor player, DiceRoll roll, Duration maxDuration, Integer maxUndo) {
		if (!isCurrentColor(player)) {
			return false;
		}
		remainingUndo = maxUndo;
		currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean hasAvailableMove(CheckerColor color) {
		return !computeAvailableMoves(color).empty;
	}
	
	shared {GameMove*} computeAvailableMoves(CheckerColor color) {
		if (isCurrentColor(color), exists roll = currentRoll, exists maxValue = roll.maxValue) {
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
	
	shared Boolean isLegalMove(CheckerColor color, Integer source, Integer target) {
		if (!isCurrentColor(color)) {
			return false;
		}
		
		if (exists roll = currentRoll) {
			return isLegalCheckerMove(color, roll, source, target);
		} else {
			return false;
		}
	}
	
	function useRollValue(CheckerColor color, Integer source, Integer target) {
		if (exists roll = currentRoll) {
			return roll.useValueAtLeast(board.distance(source, target));
		}
		return null;
	}
	
	function hitChecker(CheckerColor color, Integer source, Integer target) {
		if (board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
	}
	
	shared Boolean moveChecker(CheckerColor color, Integer source, Integer target) {
	
		if (isLegalMove(color, source, target)) {
			return false;
		}
		
		value rollValue = useRollValue(color, source, target);
		if (!exists rollValue) {
			return false;
		}
		
		value bolt = hitChecker(color, source, target);
		if (exists bolt) {
			assert (board.moveChecker(color.oppositeColor, target, board.graveyardPosition(bolt)));
		}
		assert (board.moveChecker(color, source, target));
		
		value move = GameMove(source, target, rollValue, bolt exists);
		currentMoves.push(move);
		return true;
	}
	
	shared Boolean undoTurnMoves(CheckerColor color) {
		if (!isCurrentColor(color) || remainingUndo <= 0) {
			return false;
		} else if (exists roll = currentRoll, !currentMoves.empty) {
			while (exists move = currentMoves.pop()) {
				currentRoll = roll.add(move.rollValue);
				assert (board.moveChecker(color, move.targetPosition, move.sourcePosition));
				if (move.hitBlot) {
					assert (board.moveChecker(color.oppositeColor, board.graveyardPosition(color.oppositeColor), move.targetPosition));
				}
			}
			remainingUndo--;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean timedOut(Instant now) {
		if (nextTimeout.millisecondsOfEpoch == 0) {
			return false;
		} else if (now > nextTimeout) {
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean hasWon(CheckerColor color)=> board.countCheckers(board.homePosition(color), color) == checkerCount;
	
	shared CheckerColor? switchTurn(CheckerColor color) {
		if (!isCurrentColor(color)) {
			return null;
		} else {
			currentColor = color.oppositeColor;
			return currentColor;
		}
	}
	
	shared Boolean endTurn(CheckerColor color) {
		if (!isCurrentColor(color)) {
			return false;
		} else if (hasWon(color)) {
			currentColor = null;
		}
		currentMoves.clear();
		return true;
	}
	
	shared Boolean begin(CheckerColor color) {
		if (currentColor exists) {
			return false;
		} else if (!blackReady && color == black) {
			blackReady = true;
		} else if (!whiteReady && color == white) {
			whiteReady = true;
		} else {
			return false;
		}
		
		if (blackReady && whiteReady, exists roll = currentRoll) {
			currentColor = initialColor(roll);
		}
		return true;
	}
	
	shared Boolean end() {
		if (currentRoll exists) {
			currentColor = null;
			currentRoll = null;
			nextTimeout = Instant(0);
			return true;
		}
		return false;
	}
	
	shared [Integer*] checkerCounts(CheckerColor color) => board.checkerCounts(color);
	
	shared Duration? remainingTime(Instant time) {
		if (nextTimeout.millisecondsOfEpoch == 0) {
			return null;
		}
		Duration result = nextTimeout.durationFrom(time);
		if (result.milliseconds < 0) {
			return Duration(0);
		} else {
			return result;
		}
	}
	
	shared GameState state {
		value result = GameState();
		result.currentColor = currentColor;
		result.currentRoll = currentRoll;
		result.remainingUndo = remainingUndo;
		result.blackReady = blackReady;
		result.whiteReady = whiteReady;
		result.remainingTime = remainingTime(now());
		result.blackCheckerCounts = board.checkerCounts(black);
		result.whiteCheckerCounts = board.checkerCounts(white);
		result.currentMoves = currentMoves.sequence();
		return result;
	}
	
	assign state {
		currentColor = state.currentColor;
		currentRoll = state.currentRoll;
		remainingUndo = state.remainingUndo;
		blackReady = state.blackReady;
		whiteReady = state.whiteReady;
		if (exists remainingTime = state.remainingTime) {
			nextTimeout = now().plus(remainingTime);
		} else {
			nextTimeout = Instant(0);
		}
		board.setCheckerCounts(black, state.blackCheckerCounts);
		board.setCheckerCounts(white, state.whiteCheckerCounts);
		currentMoves.clear();
		currentMoves.addAll(state.currentMoves);
	}
}