import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked
}
import ceylon.time {
	Instant,
	Duration
}

shared class Game(variable Instant nextTimeout) {

	shared GameBoard board = GameBoard();
	value currentMoves = ArrayList<GameMoveInfo>();
	
	"http://www.backgammon-play.net/GameBasic.htm"
	value initialPositionCounts = { 1 -> 2, 12 -> 5, 17 -> 3, 19 -> 5 };
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
	
	variable Integer blackJocker = 1;
	variable Integer whiteJocker = 1;
	
	function initialColor(DiceRoll diceRoll) {
		if (diceRoll.getValue(black) > diceRoll.getValue(white)) {
			return black;
		} else if (diceRoll.getValue(black) < diceRoll.getValue(white)) {
			return white;
		} else {
			return null;
		}
	}
	
	shared Boolean needInitialRoll {
		return currentRoll is Null && _currentColor is Null && nextTimeout.millisecondsOfEpoch > 0;
	}
	
	shared Boolean initialRoll(DiceRoll roll, Instant timestamp, Duration maxDuration) {
		if (currentColor exists) {
			return false;
		}
		
		blackReady = false;
		whiteReady = false;
		_currentRoll = roll;
		nextTimeout = timestamp.plus(maxDuration);
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

	shared Boolean canUndoMoves(CheckerColor playerColor) {
		if (exists color = currentColor, color == playerColor) {
			return !currentMoves.empty && remainingUndo > 0;
		} else {
			return false;
		}
	}
	
	shared Boolean canTakeTurn(CheckerColor playerColor) {
		if (playerColor == black && blackJocker > 0 && isCurrentColor(playerColor)) {
			return true;
		} else if (playerColor == white && whiteJocker > 0 && isCurrentColor(playerColor)) {
			return true;
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
		} else if (board.hasCheckersOutside(color)) {
			if (board.homePosition(color) == target) {
				return false;
			} else {
				return roll.hasRemainingValue(board.distance(source, target));
			}
		} else if (exists maxValue = roll.maxRemainingValue) {
			return maxValue >= board.distance(source, target);
		} else {
			return false;
		}
	}
	
	shared Boolean beginTurn(CheckerColor player, DiceRoll roll, Instant timestamp, Duration maxDuration, Integer maxUndo) {
		if (!isCurrentColor(player)) {
			return false;
		}
		remainingUndo = maxUndo;
		_currentRoll = roll;
		nextTimeout = timestamp.plus(maxDuration);
		return true;
	}
	
	shared {GameMove*} computeNextMoves(CheckerColor color, DiceRoll roll, Integer? sourcePosition = null) {
		if (exists maxValue = roll.maxRemainingValue) {
			value sourceRange = if (exists pos = sourcePosition) then pos..pos else board.playRange(color);
			return {
				for (source in sourceRange)
					for (target in board.targetRange(color, source, maxValue)) 
						if (isLegalCheckerMove(color, roll, source, target))
							GameMove(source, target) 
			};
		} else {
			return {}; 
		}
	}
	
	shared Boolean hasAvailableMove(CheckerColor color, DiceRoll roll) {
		return !computeNextMoves(color, roll).empty;
	}
	
	shared Boolean isLegalMove(CheckerColor color, Integer source, Integer target) {
		if (isCurrentColor(color), exists roll = currentRoll) {
			return isLegalCheckerMove(color, roll, source, target);
		} else {
			return false;
		}
	}
	
	function useRollValue(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		return roll.useValueAtLeast(board.distance(source, target));
	}
	
	function hitChecker(CheckerColor color, Integer source, Integer target) {
		if (board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
	}
	
	function makeLegalMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		value rollValue = useRollValue(color, roll, source, target);
		assert (exists rollValue);
		value bolt = hitChecker(color, source, target);
		if (exists bolt) {
			assert (board.moveChecker(color.oppositeColor, target, board.graveyardPosition(bolt)));
		}
		assert (board.moveChecker(color, source, target));
		return GameMoveInfo(source, target, rollValue, bolt exists);
	}
	
	shared Boolean moveChecker(CheckerColor color, Integer source, Integer target) {
		if (isLegalMove(color, source, target), exists roll = currentRoll) {
			currentMoves.push(makeLegalMove(color, roll, source, target));
			return true;
		} else {
			return false;
		}
	}
	
	void undoMove(GameMoveInfo move, DiceRoll roll, CheckerColor color) {
		assert (roll.addRemainingValue(move.rollValue));
		assert (board.moveChecker(color, move.targetPosition, move.sourcePosition));
		if (move.hitBlot) {
			assert (board.moveChecker(color.oppositeColor, board.graveyardPosition(color.oppositeColor), move.targetPosition));
		}
	}
	
	shared Boolean undoTurnMoves(CheckerColor color) {
		if (!isCurrentColor(color) || remainingUndo <= 0) {
			return false;
		} else if (exists roll = currentRoll, !currentMoves.empty) {
			while (exists move = currentMoves.pop()) {
				undoMove(move, roll, color);
			}
			remainingUndo--;
			return true;
		} else {
			return false;
		}
	}
	
	function compareMoveSequence({GameMoveInfo*} seq1, {GameMoveInfo*} seq2) {
		value hit1 = seq1.count((element) => element.hitBlot);
		value hit2 = seq2.count((element) => element.hitBlot);
		value hitCompare = hit1 <=> hit2;
		if (hitCompare != equal) {
			return hitCompare;
		}
		value roll1 = seq1.fold(0)((partial, element) => partial + element.rollValue);
		value roll2 = seq2.fold(0)((partial, element) => partial + element.rollValue);
		value rollCompare = roll1 <=> roll2;
		return rollCompare.reversed;
	}
	
	void appendNextMoves(HashMap<GameMove, {GameMoveInfo*}> allMoves, CheckerColor color, DiceRoll roll, GameMoveSequence? previousMove) {
		for (nextMove in computeNextMoves(color, roll, previousMove?.targetPosition)) {
			value moveInfo = makeLegalMove(color, roll, nextMove.sourcePosition, nextMove.targetPosition);
			value moveKey = GameMove(previousMove?.sourcePosition else nextMove.sourcePosition, nextMove.targetPosition);
			value newMoves = if (exists previousMove) then [moveInfo, *previousMove.moves] else [moveInfo];
			if (exists otherMoves = allMoves[moveKey]) {
				if (compareMoveSequence(otherMoves, newMoves) == smaller) {
					allMoves.put(moveKey, newMoves);
				}
			} else {
				allMoves.put(moveKey, newMoves);
			}
			if (roll.maxRemainingValue exists) {
				appendNextMoves(allMoves, color, roll, GameMoveSequence(moveKey.sourcePosition, moveKey.targetPosition, newMoves));
			}
			undoMove(moveInfo, roll, color);
		}
	}
	
	shared Map<GameMove, {GameMoveInfo*}> computeAllMoves(CheckerColor color, DiceRoll roll, Integer? sourcePosition = null) {
		value allMoves = HashMap<GameMove, {GameMoveInfo*}>(unlinked);
		if (exists sourcePosition) {
			appendNextMoves(allMoves, color, roll, GameMoveSequence(sourcePosition, sourcePosition, []));
		} else {
			appendNextMoves(allMoves, color, roll, null);
		}
		return allMoves;
	}
	
	shared [GameMove*] computeForcedMoves(CheckerColor color, DiceRoll roll) {
		value moves = computeAllMoves(color, roll);
		if (exists first = moves.first) {
			if (moves.any((element) => element.key.sourcePosition != first.key.sourcePosition)) {
				return [];
			} else {
				return moves.keys.sequence();
			}
		} else {
			return [];
		}
	}
	
	shared [GameMoveInfo*] computeBestMoveSequence(CheckerColor color, DiceRoll roll, Integer sourcePosition, Integer targetPosition) {
		value allMoves = computeAllMoves(color, roll, sourcePosition);
		value key = GameMove(sourcePosition, targetPosition);
		if (exists moves = allMoves[key]) {
			return moves.sequence().reversed;
		} else {
			return [];
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
	
	shared void forceTimeout(Instant timestamp) {
		nextTimeout = timestamp.minus(Duration(1));
	}

	shared Boolean hasWon(CheckerColor color)=> board.countCheckers(board.homePosition(color), color) == checkerCount;
	
	function switchTurn(CheckerColor currentColor, CheckerColor nextColor) {
		if (!isCurrentColor(currentColor)) {
			return false;
		} else if (hasWon(currentColor)) {
			currentMoves.clear();
			_currentColor = null;
			return false;
		} else {
			currentMoves.clear();
			_currentColor = nextColor;
			return true;
		}
	}
	
	shared Boolean endTurn(CheckerColor color) {
		return switchTurn(color, color.oppositeColor);
	}

	shared Boolean takeTurn(CheckerColor color) {
		if (color == black && blackJocker > 0 && switchTurn(color, color)) {
			blackJocker--;
			return true;
		} else if (color == white && whiteJocker > 0 && switchTurn(color, color)) {
			whiteJocker--;
			return true;
		} else {
			return false;
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
		blackReady = false;
		whiteReady = false;
		_currentColor = null;
		_currentRoll = null;
		nextTimeout = Instant(0);
		return true;
	}
	
	shared Boolean ended => nextTimeout.millisecondsOfEpoch == 0;
	
	shared Integer score {
		return (board.score(black) - board.score(white)).magnitude;
	}
	
	shared [Integer*] checkerCounts(CheckerColor color) => board.checkerCounts(color);
	
	shared Duration? remainingTime(Instant time) {
		if (nextTimeout.millisecondsOfEpoch == 0) {
			return null;
		}
		return nextTimeout.durationFrom(time);
	}
	
	shared GameState buildState(Instant timestamp) {
		value result = GameState();
		result.currentColor = currentColor;
		result.currentRoll = currentRoll;
		result.remainingUndo = remainingUndo;
		result.blackReady = blackReady;
		result.whiteReady = whiteReady;
		result.remainingTime = remainingTime(timestamp);
		result.blackJocker = blackJocker;
		result.whiteJocker = whiteJocker;
		result.blackCheckerCounts = board.checkerCounts(black);
		result.whiteCheckerCounts = board.checkerCounts(white);
		result.currentMoves = currentMoves.sequence();
		return result;
	}
	
	shared void resetState(GameState state, Instant timestamp) {
		_currentColor = state.currentColor;
		_currentRoll = state.currentRoll;
		remainingUndo = state.remainingUndo;
		blackReady = state.blackReady;
		whiteReady = state.whiteReady;
		if (exists remainingTime = state.remainingTime) {
			nextTimeout = timestamp.plus(remainingTime);
		} else {
			nextTimeout = Instant(0);
		}
		blackJocker = state.blackJocker;
		whiteJocker = state.whiteJocker;
		board.setCheckerCounts(black, state.blackCheckerCounts);
		board.setCheckerCounts(white, state.whiteCheckerCounts);
		currentMoves.clear();
		currentMoves.addAll(state.currentMoves);
	}
	
	shared Integer remainingJocker(CheckerColor color) {
		return switch (color)
			case (black) blackJocker
			case (white) whiteJocker;
	}
}

