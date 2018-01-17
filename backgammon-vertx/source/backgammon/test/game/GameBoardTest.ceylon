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
	CheckerColor
}

class GameBoardTest() {
	
	value board = GameBoard();
	
	test
	shared void emptyBoardHasNoChecker() {
		for (i in 0:boardPointCount) {
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
	}
	
	test
	shared void putCheckerOutsideHomeArea() {
		board.putNewCheckers(10, black, 1);
		assert (board.hasCheckersOutside(black));
	}
	
	test
	shared void putCheckerInHomeArea() {
		board.putNewCheckers(5, white, 1);
		assert (!board.hasCheckersOutside(white));
	}
	
	test
	shared void distanceNotNegative() {
		value result = board.distance(10, 5);
		assert (result == 5);
	}
	
	test
	shared void countCheckersWithInitialState() {
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void countCheckersWithOneBlackChecker() {
		board.putNewCheckers(1, black, 1);
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void countCheckersWithTwoWhiteCheckers() {
		board.putNewCheckers(1, white, 2);
		value blackCheckers = board.checkerCounts(black);
		assert (blackCheckers == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value whiteCheckers = board.checkerCounts(white);
		assert (whiteCheckers == [0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	}
	
	test
	shared void setCheckerCountsWithOneBlackChecker() {
		board.setCheckerCounts(black, [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value result = board.countCheckers(1, black);
		assert (result == 1);
	}
	
	test
	shared void setCheckerCountsWithOneWhiteChecker() {
		board.setCheckerCounts(white, [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		value result = board.countCheckers(1, white);
		assert (result == 1);
	}
	
	test
	shared void checkSourceRange() {
		assert (0..24 == board.playRange(black));
		assert (25..1 == board.playRange(white));
	}
	
	test
	shared void targetRangeSpansWholeDistance() {
		assert (1..2 == board.targetRange(black, 0, 2));
		assert (24..23 == board.targetRange(white, 25, 2));
		assert (22..25 == board.targetRange(black, 21, 4));
		assert (3..0 == board.targetRange(white, 4, 4));
	}
	
	test
	shared void targetRangeIsLimitedByHome() {
		assert (22..25 == board.targetRange(black, 21, 6));
		assert (4..0 == board.targetRange(white, 5, 6));
	}
	
	test
	shared void noTargetPositionsForInvalidInput() {
		assert (board.targetRange(black, -1, 4).empty);
		assert (board.targetRange(black, 26, 4).empty);
		assert (board.targetRange(white, -1, 4).empty);
		assert (board.targetRange(white, 26, 4).empty);
		assert (board.targetRange(black, 2, -1).empty);
		assert (board.targetRange(black, 2, 26).empty);
		assert (board.targetRange(white, 24, -1).empty);
		assert (board.targetRange(white, 24, 26).empty);
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
		assert (2 * (boardPointCount-1) == board.remainingDistance(black));
		assert (5 * (boardPointCount-1) == board.remainingDistance(white));
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