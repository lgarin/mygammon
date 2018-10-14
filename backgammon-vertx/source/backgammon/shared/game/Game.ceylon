import ceylon.collection {
	ArrayList,
	HashMap,
	unlinked
}
import ceylon.time {
	Instant,
	Duration
}
import backgammon.shared {

	GameJoker,
	undoTurnJoker,
	takeTurnJoker,
	controlRollJoker,
	replayTurnJoker,
	placeCheckerJoker,
	allGameJokers
}

shared class Game(variable Instant nextTimeout) {

	shared GameBoard board = GameBoard();
	
	value currentMoves = ArrayList<GameMoveInfo>();
	
	value checkerCount = 12; 
	board.putNewCheckers(whiteStartPosition, white, checkerCount);
	board.putNewCheckers(blackStartPosition, black, checkerCount);

	variable CheckerColor? _currentColor = null;
	variable DiceRoll? _currentRoll = null;

	shared CheckerColor? currentColor => _currentColor;
	shared DiceRoll? currentRoll => _currentRoll;
	
	variable Integer remainingUndo = 0;
	variable Boolean blackReady = false;
	variable Boolean whiteReady = false;
	
	variable [GameJoker*] blackJokers = allGameJokers;
	variable [GameJoker*] whiteJokers = allGameJokers;
	
	void useJoker(CheckerColor color, GameJoker joker) {
		switch (color)
		case (black) { blackJokers = blackJokers.select((current) => current != joker); }
		case (white) { whiteJokers = whiteJokers.select((current) => current != joker); }
	}
	
	variable GameState? startState = null;
	shared Boolean started => startState exists;
	
	value statistic = GameStatistic(board.remainingDistance(black), checkerCount);
	shared GameStatistic currentStatistic => statistic.copy();
	
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
	
	shared Boolean canPlayAnyJoker(CheckerColor playerColor) => remainingJokerCount(playerColor) > 0 && isCurrentColor(playerColor);
	
	value previousTurnColor => startState?.previousState?.currentColor;
	
	shared Boolean canPlayJoker(CheckerColor playerColor, GameJoker joker) {
		if (isCurrentColor(playerColor) && remainingJokers(playerColor).contains(joker)) {
			if (joker == undoTurnJoker || joker == placeCheckerJoker) {
				return (previousTurnColor else playerColor) != playerColor && currentMoves.empty;
			} else if (joker == replayTurnJoker) {
				return !(currentRoll?.isJoker else true) && currentMoves.empty;
			} else {
				return true;
			}
		} else {
			return false;
		}
	}
	
	function isLegalCheckerPlacement(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (!board.isInRange(source) || !board.isInRange(target)) {
			return false;
		} else if (board.directionSign(color) != (target - source).sign) {
			return false;
		} else if (board.countCheckers(source, color.oppositeColor) == 0) {
			return false;
		} else if (board.countCheckers(target, color) > 0) {
			return false;
		} else if (board.graveyardPosition(color.oppositeColor) == source) {
			return false;
		} else if (board.homePosition(color.oppositeColor) == source) {
			return false;
		} else if (exists minValue = roll.minRemainingValue) {
			return -minValue >= board.distance(source, target);
		} else {
			return false;
		}
	}
	
	function isLegalCheckerMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (roll.isJoker) {
			return isLegalCheckerPlacement(color, roll, source, target);
		} else if (!board.isInRange(source) || !board.isInRange(target)) {
			return false;
		} else if (board.directionSign(color) != (target - source).sign) {
			return false;
		} else if (board.hasCheckerInGraveyard(color) && board.graveyardPosition(color) != source) {
			return false;
		} else if (board.countCheckers(source, color) == 0) {
			return false;
		} else if (board.countCheckers(target, color.oppositeColor) > 1) {
			return false;
		} else if (board.homePosition(color) == target) {
			if (board.hasCheckersOutside(color)) {
				return false;
			} else if (exists maxValue = roll.maxRemainingValue) {
				return maxValue >= board.distance(source, target);
			} else {
				return false;
			}
		} else {
			return roll.hasRemainingValue(board.distance(source, target));
		}
	}
	
	shared Boolean beginTurn(CheckerColor player, DiceRoll roll, Instant timestamp, Duration maxDuration, Integer maxUndo) {
		if (!isCurrentColor(player)) {
			return false;
		}
		remainingUndo = maxUndo;
		_currentRoll = roll;
		nextTimeout = timestamp.plus(maxDuration);
		if (exists state = startState) {
			state.previousState = null;
		}
		startState = buildState(timestamp);
		statistic.side(player).turnStarted(roll, timestamp);
		return true;
	}
	
	function computeSourceRange(CheckerColor color, Integer? sourcePosition) {
		if (exists position = sourcePosition) {
			return position..position;
		} else {
			return board.playRange(color);
		}
	}
	
	function computeMaxDistance(DiceRoll roll) {
		if (roll.isJoker, exists minValue = roll.minRemainingValue) {
			return minValue;
		} else if (exists maxValue = roll.maxRemainingValue) {
			return maxValue;
		} else {
			return 0;
		}
	}
	
	shared {GameMove*} computeNextMoves(CheckerColor color, DiceRoll roll, Integer? sourcePosition = null) {
		value maxDistance = computeMaxDistance(roll);
		if (maxDistance == 0) {
			return {};
		}
		value sourceColor = roll.isJoker then color.oppositeColor else color;
		return {
			for (source in computeSourceRange(sourceColor, sourcePosition))
				for (target in board.targetRange(sourceColor, source, maxDistance)) 
					if (isLegalCheckerMove(color, roll, source, target))
						GameMove(source, target) 
		};
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

	function hitChecker(CheckerColor color, Integer source, Integer target) {
		if (board.countCheckers(target, color.oppositeColor) > 0) {
			return color.oppositeColor;
		}
		return null;
	}
	
	function makeLegalPlacement(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		value rollValue = roll.useValueAtMost(board.distance(source, target));
		assert (exists rollValue);
		assert (board.moveChecker(color.oppositeColor, source, target));
		return GameMoveInfo(source, target, rollValue, false);
	}
	
	function makeLegalMove(CheckerColor color, DiceRoll roll, Integer source, Integer target) {
		if (roll.isJoker) {
			return makeLegalPlacement(color, roll, source, target);
		}
		value rollValue = roll.useValueAtLeast(board.distance(source, target));
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
			value move = makeLegalMove(color, roll, source, target);
			currentMoves.push(move);
			statistic.side(color).movedChecker(move.distance, move.hitBlot);
			return true;
		} else {
			return false;
		}
	}
	
	void undoMove(GameMoveInfo move, DiceRoll roll, CheckerColor color) {
		assert (roll.addRemainingValue(move.rollValue));
		assert (board.moveChecker(roll.adaptColor(color), move.targetPosition, move.sourcePosition));
		if (move.hitBlot) {
			value oppositeColor = roll.adaptColor(color).oppositeColor;
			assert (board.moveChecker(oppositeColor, board.graveyardPosition(oppositeColor), move.targetPosition));
		}
	}
	
	shared Boolean undoMoves(CheckerColor color) {
		if (!isCurrentColor(color) || remainingUndo <= 0) {
			return false;
		} else if (exists roll = currentRoll, !currentMoves.empty) {
			while (exists move = currentMoves.pop()) {
				undoMove(move, roll, color);
				statistic.side(color).movedChecker(-move.distance, move.hitBlot);
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
		value roll1 = seq1.fold(0)((partial, element) => partial + element.rollValue.magnitude);
		value roll2 = seq2.fold(0)((partial, element) => partial + element.rollValue.magnitude);
		return roll2 <=> roll1;
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
			if (roll.remainingValues nonempty) {
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
	
	function switchTurn(CheckerColor currentColor, CheckerColor nextColor, Boolean joker, Instant timestamp) {
		if (!isCurrentColor(currentColor)) {
			return false;
		} else if (hasWon(currentColor)) {
			currentMoves.clear();
			_currentColor = null;
			statistic.side(currentColor).turnEnded(timestamp, false);
			return false;
		} else {
			currentMoves.clear();
			_currentColor = nextColor;
			statistic.side(currentColor).turnEnded(timestamp, joker);
			return true;
		}
	}
	
	shared Boolean endTurn(CheckerColor color, Instant timestamp) {
		if (switchTurn(color, color.oppositeColor, false, timestamp)) {
			return true;
		} else {
			return false;
		}
	}

	shared Boolean takeTurn(CheckerColor color, Instant timestamp) {
		if (canPlayJoker(color, takeTurnJoker) && switchTurn(color, color, true, timestamp)) {
			useJoker(color, takeTurnJoker);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean controlRoll(CheckerColor color, Instant timestamp) {
		if (canPlayJoker(color, controlRollJoker) && switchTurn(color, color.oppositeColor, true, timestamp)) {
			useJoker(color, controlRollJoker);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean undoTurn(CheckerColor color, Instant timestamp) {
		if (canPlayJoker(color, undoTurnJoker) && switchTurn(color, color.oppositeColor, true, timestamp), exists previousState = startState?.previousState) {
			resetState(previousState, timestamp);
			useJoker(color, undoTurnJoker);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean replayTurn(CheckerColor color, Instant timestamp) {
		if (canPlayJoker(color, replayTurnJoker) && switchTurn(color, color, true, timestamp), exists previousState = startState) {
			resetState(previousState, timestamp);
			useJoker(color, replayTurnJoker);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean placeChecker(CheckerColor color, Instant timestamp) {
		if (canPlayJoker(color, placeCheckerJoker) && switchTurn(color, color, true, timestamp), exists previousState = startState) {
			resetState(previousState, timestamp);
			useJoker(color, placeCheckerJoker);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean begin(CheckerColor color, Instant timestamp) {
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
			statistic.gameStarted(timestamp);
		}
		return true;
	}
	
	shared Boolean end(Instant timestamp, CheckerColor? winnerColor) {
		statistic.gameEnded(timestamp, winnerColor, board.remainingDistance(black), board.remainingDistance(white));
		
		blackReady = false;
		whiteReady = false;
		_currentColor = null;
		_currentRoll = null;
		nextTimeout = Instant(0);
		return true;
	}
	
	shared Boolean ended => nextTimeout.millisecondsOfEpoch == 0;
	
	shared Integer score => (board.remainingDistance(black) - board.remainingDistance(white)).magnitude;
	
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
		result.blackJokers = blackJokers;
		result.whiteJokers = whiteJokers;
		result.blackCheckerCounts = board.checkerCounts(black);
		result.whiteCheckerCounts = board.checkerCounts(white);
		result.currentMoves = currentMoves.sequence();
		result.previousState = startState;
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
		blackJokers = state.blackJokers;
		whiteJokers = state.whiteJokers;
		board.setCheckerCounts(black, state.blackCheckerCounts);
		board.setCheckerCounts(white, state.whiteCheckerCounts);
		currentMoves.clear();
		currentMoves.addAll(state.currentMoves);
		startState = state.previousState;
	}
	
	shared Integer remainingJokerCount(CheckerColor color) {
		return switch (color)
			case (black) blackJokers.size
			case (white) whiteJokers.size;
	}
	
	shared [GameJoker*] remainingJokers(CheckerColor color) {
		return switch (color)
		case (black) blackJokers
		case (white) whiteJokers;
	}
}

