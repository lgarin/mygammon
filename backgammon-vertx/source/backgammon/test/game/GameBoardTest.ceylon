import ceylon.test {
	test
}
import backgammon.shared.game {
	whiteGraveyardPosition,
	whiteHomePosition,
	white,
	blackHomePosition,
	GameBoard,
	boardPointCount,
	black,
	blackGraveyardPosition,
	CheckerColor,
	whiteStartPosition,
	blackStartPosition,
	wholePlayRange
}

class GameBoardTest() {
	
	value board = GameBoard();
	
	test
	shared void emptyBoardHasNoChecker() {
		for (i in wholePlayRange) {
			assert (board.countCheckers(i, black) == 0);
			assert (board.countCheckers(i, white) == 0);
		}
	}
	
	test
	shared void emptyBoardHasNoCheckerInGraveyard() {
		assert (!board.hasCheckerInGraveyard(black));
		assert (!board.hasCheckerInGraveyard(white));
	}
	
	test
	shared void emptyBoardHasNoCheckerOutsideHomeArea() {
		assert (!board.hasCheckersOutside(black));
		assert (!board.hasCheckersOutside(white));
	}
	
	test
	shared void testGraveyardPosition() {
		assert (board.graveyardPosition(black) == blackGraveyardPosition);
		assert (board.graveyardPosition(white) == whiteGraveyardPosition);
	}
	
	test
	shared void testHomePosition() {
		assert (board.homePosition(black) == blackHomePosition);
		assert (board.homePosition(white) == whiteHomePosition);
	}
	
	test
	shared void testStartPosition() {
		assert (board.startPosition(black) == blackStartPosition);
		assert (board.startPosition(white) == whiteStartPosition);
	}
	
	test
	shared void addCheckerToFreePosition() {
		value result = board.putNewCheckers(2, black, 1);
		assert (result);
		assert (board.countCheckers(2, black) == 1);
	}
	
	test
	shared void addCheckerToOccupiedPosition() {
		board.putNewCheckers(2, white, 1);
		value result = board.putNewCheckers(2, black, 1);
		assert (result);
		assert (board.countCheckers(2, black) == 1);
		assert (board.countCheckers(2, white) == 1);
	}
	
	test
	shared void addNegativeNumberOfCheckers() {
		value result = board.putNewCheckers(4, black, -1);
		assert (!result);
	}
	
	test
	shared void cannotMoveFromPositionWithoutChecker() {
		value result = board.moveChecker(white, 1, 2);
		assert (!result);
	}
	
	test
	shared void moveCheckerToFreePosition() {
		board.putNewCheckers(2, white, 1);
		value result = board.moveChecker(white, 2, 22);
		assert (result);
		assert (board.countCheckers(2, white) == 0);
		assert (board.countCheckers(22, white) == 1);
	}
	
	test
	shared void moveCheckerToOccupiedPosition() {
		board.putNewCheckers(2, white, 1);
		board.putNewCheckers(22, black, 1);
		value result = board.moveChecker(white, 2, 22);
		assert (result);
		assert (board.countCheckers(2, white) == 0);
		assert (board.countCheckers(22, white) == 1);
		assert (board.countCheckers(22, black) == 1);
	}
	
	test
	shared void putCheckerInGraveyard() {
		board.putNewCheckers(board.graveyardPosition(black), black, 1);
		assert (board.hasCheckerInGraveyard(black));
		
		board.putNewCheckers(board.graveyardPosition(white), white, 1);
		assert (board.hasCheckerInGraveyard(white));
	}
	
	test
	shared void putCheckerOutsideHomeArea() {
		board.putNewCheckers(17, black, 1);
		assert (board.hasCheckersOutside(black));
		
		board.putNewCheckers(7, white, 1);
		assert (board.hasCheckersOutside(white));
	}
	
	test
	shared void putCheckerInHomeArea() {
		board.putNewCheckers(6, white, 1);
		assert (!board.hasCheckersOutside(white));
		
		board.putNewCheckers(18, black, 1);
		assert (!board.hasCheckersOutside(black));
	}
	
	test
	shared void putCheckerAtStart() {
		board.putNewCheckers(whiteStartPosition, white, 1);
		assert (board.hasCheckersOutside(white));
		
		board.putNewCheckers(blackStartPosition, black, 1);
		assert (board.hasCheckersOutside(black));
	}
	
	test
	shared void distanceNotNegative() {
		value result = board.distance(10, 5);
		assert (result == 5);
	}
	
	test
	shared void countCheckersWithInitialState() {
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void countCheckersWithOneBlackChecker() {
		board.putNewCheckers(1, black, 1);
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void countCheckersWithTwoWhiteCheckers() {
		board.putNewCheckers(1, white, 2);
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void setCheckerCountsWithOneBlackChecker() {
		board.setCheckerCounts(black, [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value result = board.countCheckers(1, black);
		assert (result == 1);
	}
	
	test
	shared void setCheckerCountsWithOneWhiteChecker() {
		board.setCheckerCounts(white, [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value result = board.countCheckers(1, white);
		assert (result == 1);
	}
	
	test
	shared void checkSourceRange() {
		assert (-1..24 == board.playRange(black));
		assert (26..1 == board.playRange(white));
	}
	
	test
	shared void targetRangeSpansWholeDistance() {
		assert (1..2 == board.targetRange(black, 0, 2));
		assert (24..23 == board.targetRange(white, 26, 2));
		assert (22..25 == board.targetRange(black, 21, 4));
		assert (4..1 == board.targetRange(white, 5, 4));
	}
	
	test
	shared void targetRangeIsLimitedByHome() {
		assert (22..25 == board.targetRange(black, 21, 6));
		assert (5..0 == board.targetRange(white, 6, 6));
	}
	
	test
	shared void noTargetPositionsForInvalidInput() {
		assert (board.targetRange(black, -2, 4).empty);
		assert (board.targetRange(black, 27, 4).empty);
		assert (board.targetRange(white, 0, 4).empty);
		assert (board.targetRange(white, 28, 4).empty);
		assert (board.targetRange(black, 2, -1).empty);
		assert (board.targetRange(black, 2, 27).empty);
		assert (board.targetRange(white, 24, -1).empty);
		assert (board.targetRange(white, 24, 26).empty);
	}
	
	test
	shared void targetPositionsForStart() {
		assert (1..4 == board.targetRange(black, blackStartPosition, 4));
		assert (24..21 == board.targetRange(white, whiteStartPosition, 4));
	}
	
	test
	shared void targetPositionsForGraveyard() {
		assert (1..4 == board.targetRange(black, blackGraveyardPosition, 4));
		assert (24..21 == board.targetRange(white, whiteGraveyardPosition, 4));
	}
	
	test
	shared void targetPositionsForHome() {
		assert ([] == board.targetRange(black, blackHomePosition, 4));
		assert ([] == board.targetRange(white, whiteHomePosition, 4));
	}
	
	test
	shared void scoreWithEmptyBoard() {
		assert (0 == board.remainingDistance(black));
		assert (0 == board.remainingDistance(white));
	}
	
	test
	shared void scoreWithHomeCheckers() {
		board.putNewCheckers(blackHomePosition, black, 2);
		board.putNewCheckers(whiteHomePosition, white, 5);
		assert (0 == board.remainingDistance(black));
		assert (0 == board.remainingDistance(white));
	}
	
	test
	shared void scoreWithGraveyardCheckers() {
		board.putNewCheckers(blackGraveyardPosition, black, 2);
		board.putNewCheckers(whiteGraveyardPosition, white, 5);
		assert (2 * (boardPointCount+1) == board.remainingDistance(black));
		assert (5 * (boardPointCount+1) == board.remainingDistance(white));
	}
	
	test
	shared void scoreWithStartCheckers() {
		board.putNewCheckers(blackStartPosition, black, 2);
		board.putNewCheckers(whiteStartPosition, white, 5);
		assert (2 * (boardPointCount+1) == board.remainingDistance(black));
		assert (5 * (boardPointCount+1) == board.remainingDistance(white));
	}
	
	void addCheckers(CheckerColor color, Integer relativePosition, Integer checkerCount) {
		assert (board.putNewCheckers(board.homePosition(color) - relativePosition * board.directionSign(color), color, checkerCount));
	}
	
	test
	shared void scoreWithDistributedCheckers() {
		addCheckers(black, 2, 1);
		addCheckers(black, 3, 2);
		addCheckers(black, 6, 1);
		addCheckers(white, 2, 1);
		addCheckers(white, 3, 2);
		addCheckers(white, 6, 1);
		assert (14 == board.remainingDistance(black));
		assert (14 == board.remainingDistance(white));
	}
}