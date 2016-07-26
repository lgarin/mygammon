import ceylon.time {
	Instant,
	now,
	Duration
}
import ceylon.collection {

	ArrayList
}
import ceylon.test {

	test
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

	variable CheckerColor? currentColorVar = null;
	variable DiceRoll? currentRollVar = null;

	shared CheckerColor? currentColor => currentColorVar;
	shared DiceRoll? currentRoll => currentRollVar;
	
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
		currentRollVar = roll;
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
	
	shared Boolean canUndoMoves(CheckerColor playerColor) {
		if (exists color = currentColor, color == playerColor) {
			return !currentMoves.empty;
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
		currentRollVar = roll;
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
				currentRollVar = roll.add(move.rollValue);
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
	
	shared Boolean endTurn(CheckerColor color) {
		if (!isCurrentColor(color)) {
			return false;
		} else if (hasWon(color)) {
			currentMoves.clear();
			currentColorVar = null;
			return false;
		} else {
			currentMoves.clear();
			if (exists roll = currentRoll, roll.isPair) {
				currentColorVar = color;
			} else {
				currentColorVar = color.oppositeColor;
			}
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
			currentColorVar = initialColor(roll);
		}
		return true;
	}
	
	shared Boolean end() {
		if (currentRoll exists) {
			currentColorVar = null;
			currentRollVar = null;
			nextTimeout = Instant(0);
			return true;
		}
		return false;
	}
	
	shared Boolean ended {
		return whiteReady && blackReady && currentColor is Null;
	}
	
	shared Boolean started {
		return whiteReady && blackReady && currentColor exists;
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
		currentColorVar = state.currentColor;
		currentRollVar = state.currentRoll;
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
	shared CheckerColor? winner {
		if (hasWon(black)) {
			return black;
		} else if (hasWon(white)) {
			return white;
		} else {
			return null;
		}
	}
}

class GameTest() {
	
	value game = Game();
	
	test
	shared void checkInitialGame() {
		assert (game.currentColor is Null);
		assert (!game.isCurrentColor(black));
		assert (!game.isCurrentColor(white));
		assert (game.currentRoll is Null);
		assert ([0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0] == game.board.checkerCounts(black));
		assert ([0, 0, 0, 0, 0, 0, 5, 0, 3, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0] == game.board.checkerCounts(white));
		assert (!game.started);
		assert (!game.ended);
		assert (game.winner is Null);
		assert (!game.mustRollDice(black));
		assert (!game.mustRollDice(white));
		assert (!game.mustMakeMove(black));
		assert (!game.canUndoMoves(white));
		assert (!game.canUndoMoves(black));
		assert (game.remainingTime(now()) is Null);
		assert (!game.timedOut(now()));
	}
	
	test
	shared void checkInitialState() {
		value state = game.state;
		assert (state.currentColor is Null);
		assert (state.currentRoll is Null);
		assert (state.blackCheckerCounts == [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0]);
		assert (state.whiteCheckerCounts == [0, 0, 0, 0, 0, 0, 5, 0, 3, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0]);
		assert (!state.blackReady);
		assert (!state.whiteReady);
		assert (state.remainingUndo == 0);
		assert (state.currentMoves.empty);
		assert (state.remainingTime is Null);
	}
	
	test
	shared void computeInitalBlackMoves() {
		value moves = game.computeAvailableMoves(black, DiceRoll(3, 1));
		assert (moves.contains(GameMove(1, 2, 1, false)));
		assert (moves.contains(GameMove(1, 4, 3, false)));
		assert (moves.contains(GameMove(12, 15, 3, false)));
		assert (moves.contains(GameMove(17, 18, 1, false)));
		assert (moves.contains(GameMove(17, 20, 3, false)));
		assert (moves.contains(GameMove(19, 20, 1, false)));
		assert (moves.contains(GameMove(19, 22, 3, false)));
		assert (moves.size == 7);
	}
	
	test
	shared void computeInitalWhiteMoves() {
		value moves = game.computeAvailableMoves(white, DiceRoll(1, 5));
		assert (moves.contains(GameMove(24, 23, 1, false)));
		assert (moves.contains(GameMove(13, 8, 5, false)));
		assert (moves.contains(GameMove(8, 7, 1, false)));
		assert (moves.contains(GameMove(8, 3, 5, false)));
		assert (moves.contains(GameMove(6, 5, 1, false)));
		assert (moves.size == 5);
	}
}