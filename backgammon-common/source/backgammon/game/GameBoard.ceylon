import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
final class BoardPoint(shared Integer position) {
	variable Integer whiteCount = 0;
	variable Integer blackCount = 0;
	
	shared void putChecker(CheckerColor color, Integer count) => resetChecker(color, countCheckers(color) + count);
	
	shared void resetChecker(CheckerColor color, Integer count) {
		switch (color)
		case (black) {blackCount = count;}
		case (white) {whiteCount = count;}
	}
	
	shared Boolean removeChecker(CheckerColor color) {
		switch (color)
		case (black) { 
			if (blackCount > 0) {
				blackCount--;
				return true; 
			} else {
				return false;
			}
		}
		case (white) { 
			if (whiteCount > 0) {
				whiteCount--;
				return true; 
			} else {
				return false;
			}
		}
	}
	
	shared Boolean hasChecker(CheckerColor color) => countCheckers(color) > 0;
	
	shared Integer countCheckers(CheckerColor color) {
		switch (color)
		case (black) {return blackCount;}
		case (white) {return whiteCount;}
	}
}

shared Integer boardPointCount = 26;

shared Integer whiteGraveyardPosition = boardPointCount - 1;
shared Integer whiteHomePosition = 0;

shared Integer blackGraveyardPosition = 0;
shared Integer blackHomePosition = boardPointCount - 1;

shared final class GameBoard() {

	value whitePlayRange = 24..7;
	value blackPlayRange = 1..18;
	
	value whiteSourceRange = whiteGraveyardPosition..whiteHomePosition;
	value blackSourceRange = blackGraveyardPosition..blackHomePosition;

	shared Integer graveyardPosition(CheckerColor color) {
		switch (color)
		case (white) { return whiteGraveyardPosition; }
		case (black) { return blackGraveyardPosition; }
	}
	
	shared Integer homePosition(CheckerColor color) {
		switch (color)
		case (white) { return whiteHomePosition; }
		case (black) { return blackHomePosition; }
	}
	
	shared Range<Integer> playRange(CheckerColor color) {
		switch (color)
		case (white) { return whitePlayRange; }
		case (black) { return blackPlayRange; }
	}
	
	shared Range<Integer> sourceRange(CheckerColor color) {
		switch (color)
		case (white) { return whiteSourceRange; }
		case (black) { return blackSourceRange; }
	}
	
	shared Integer directionSign(CheckerColor color) {
		switch (color)
		case (white) { return -1; }
		case (black) { return +1; }
	}
	
	shared [Integer*] targetRange(CheckerColor color, Integer sourcePosition, Integer maxDistance) {
		if (maxDistance < 1 || maxDistance >= boardPointCount) {
			return [];
		}
		switch (color)
		case (white) {
			if (sourcePosition <= whiteHomePosition || sourcePosition > whiteGraveyardPosition) {
				return [];
			}
			value endPosition = sourcePosition-maxDistance;
			if (endPosition > whiteHomePosition) {  
				return sourcePosition-1..endPosition; 
			} else {
				return sourcePosition-1..whiteHomePosition;
			}
		}
		case (black) {
			if (sourcePosition >= blackHomePosition || sourcePosition < blackGraveyardPosition) {
				return [];
			}
			value endPosition = sourcePosition+maxDistance;
			if (endPosition < boardPointCount) {  
				return sourcePosition+1..endPosition; 
			} else {
				return sourcePosition+1..blackHomePosition;
			}
		}
	}
	
	shared Boolean isInRange(Integer position) {
		return 0 <= position < boardPointCount; 
	}

	ArrayList<BoardPoint> points = ArrayList<BoardPoint>(boardPointCount);
	for (i in 0:boardPointCount) {
		points.add(BoardPoint(i));
	}

	shared Boolean putNewCheckers(Integer position, CheckerColor color, Integer count) {
		if (count <= 0) {
			return false; 
		} else if (exists boardPoint = points[position]) {
			boardPoint.putChecker(color, count);
			return true;
		} else {
			return false;
		}
	}
	
	shared Integer countCheckers(Integer position, CheckerColor color) {
		if (exists boardPoint = points[position]) {
			return boardPoint.countCheckers(color);
		} else {
			return 0;
		}
	}
	
	function hasChecker(Integer position, CheckerColor color) {
		if (exists boardPoint = points[position]) {
			return boardPoint.hasChecker(color);
		} else {
			return false;
		}
	}
	
	shared Boolean hasCheckerInGraveyard(CheckerColor color) => hasChecker(graveyardPosition(color), color);

	shared Boolean hasCheckersOutsideHomeArea(CheckerColor color) {
		return playRange(color).any((Integer element) => hasChecker(element, color));
	}
	
	shared Boolean moveChecker(CheckerColor color, Integer sourcePosition, Integer targetPosition) {
		if (exists sourcePoint = points[sourcePosition], exists targetPoint = points[targetPosition]) {
			if (sourcePoint.removeChecker(color)) {
				targetPoint.putChecker(color, 1);
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared Integer distance(Integer sourcePosition, Integer targetPosition) => (targetPosition - sourcePosition).magnitude;
	
	shared void removeAllCheckers() {
		for (p in points) {
			p.resetChecker(black, 0);
			p.resetChecker(white, 0);
		}
	}
	
	shared [Integer*] checkerCounts(CheckerColor color) {
		return [for (p in points) p.countCheckers(color)];
	}
	
	shared void setCheckerCounts(CheckerColor color, {Integer*} counts) {
		value iterator = counts.iterator();
		for (p in points) {
			if (is Integer count = iterator.next()) {
				p.resetChecker(color, count);
			} else {
				p.resetChecker(color, 0);
			}
		}
	}
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
		assert (!board.hasCheckersOutsideHomeArea(black));
		assert (!board.hasCheckersOutsideHomeArea(white));
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
		assert (board.hasCheckersOutsideHomeArea(black));
	}
	
	test
	shared void putCheckerInHomeArea() {
		board.putNewCheckers(5, white, 1);
		assert (!board.hasCheckersOutsideHomeArea(white));
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
		assert (0..25 == board.sourceRange(black));
		assert (25..0 == board.sourceRange(white));
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
}