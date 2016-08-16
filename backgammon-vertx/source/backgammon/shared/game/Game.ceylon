import ceylon.collection {
	ArrayList
}
import ceylon.time {
	Instant,
	now,
	Duration
}

shared class Game() {

	shared GameBoard board = GameBoard();
	value currentMoves = ArrayList<GameMove>();
	
	"http://www.backgammon-play.net/GameBasic.htm"
	value initialPositionCounts = [ 1 -> 2, 12 -> 5, 17 -> 3, 19 -> 5 ];
	value checkerCount = sum(initialPositionCounts.map((Integer->Integer element) => element.item)); 
	
	for (value element in initialPositionCounts) {
		assert (board.putNewCheckers(whiteGraveyardPosition - element.key, white, element.item));
		assert (board.putNewCheckers(element.key + blackGraveyardPosition, black, element.item));
	}

	variable CheckerColor? _currentColor = null;
	variable DiceRoll? _currentRoll = null;

	shared CheckerColor? currentColor => _currentColor;
	shared DiceRoll? currentRoll => _currentRoll;
	
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
		_currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean isCurrentColor(CheckerColor color) => currentColor?.equals(color) else false;
	
	shared Boolean mustRollDice(CheckerColor playerColor) {
		if (currentColor exists || !currentRoll exists) {
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
	
	shared Boolean canUndoMoves(CheckerColor playerColor) {
		if (exists color = currentColor, color == playerColor) {
			return !currentMoves.empty && remainingUndo > 0;
		} else {
			return false;
		}
	}
	
	function isLegalCheckerMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (!board.isInRange(source) || !board.isInRange(target)) {
			return false;
		} else if (board.directionSign(color) != (target - source).sign) {
			return false;
		} else if (board.hasCheckerInGraveyard(color) && board.graveyardPosition(color) != source) {
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
		_currentRoll = roll;
		nextTimeout = now().plus(maxDuration);
		return true;
	}
	
	shared Boolean hasAvailableMove(CheckerColor color, DiceRoll roll) {
		return !computeAvailableMoves(color, roll).empty;
	}
	
	shared {GameMove*} computeAvailableMoves(CheckerColor color, DiceRoll roll, Integer? sourcePosition = null) {
		if (exists maxValue = roll.maxValue) {
			value sourceRange = if (exists pos = sourcePosition) then pos..pos else board.sourceRange(color);
			return {
				for (source in sourceRange)
					for (target in board.targetRange(color, source, maxValue)) 
						if (isLegalCheckerMove(color, roll, source, target), exists rollValue = roll.minValueAtLeast(board.distance(source, target)))
							GameMove(source, target, rollValue, board.countCheckers(target, color.oppositeColor) > 0) 
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
	
		if (!isLegalMove(color, source, target)) {
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
				roll.add(move.rollValue);
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
		if (ended) {
			return false;
		} else if (now > nextTimeout) {
			return true;
		} else {
			return false;
		}
	}
	
	shared void forceTimeout() {
		nextTimeout = now().minus(Duration(1));
	}

	shared Boolean hasWon(CheckerColor color)=> board.countCheckers(board.homePosition(color), color) == checkerCount;
	
	shared Boolean endTurn(CheckerColor color) {
		if (!isCurrentColor(color)) {
			return false;
		} else if (hasWon(color)) {
			currentMoves.clear();
			_currentColor = null;
			return false;
		} else {
			currentMoves.clear();
			_currentColor = color.oppositeColor;
			return true;
		}
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
			_currentColor = initialColor(roll);
		}
		return true;
	}
	
	shared Boolean end() {
		if (currentRoll exists) {
			_currentColor = null;
			_currentRoll = null;
			nextTimeout = Instant(0);
			return true;
		}
		return false;
	}
	
	shared Boolean ended => nextTimeout.millisecondsOfEpoch == 0;
	
	shared [Integer*] checkerCounts(CheckerColor color) => board.checkerCounts(color);
	
	shared Duration? remainingTime(Instant time) {
		if (nextTimeout.millisecondsOfEpoch == 0) {
			return null;
		}
		return nextTimeout.durationFrom(time);
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
		result.currentMoves = currentMoves.clone();
		return result;
	}
	
	assign state {
		_currentColor = state.currentColor;
		_currentRoll = state.currentRoll;
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
