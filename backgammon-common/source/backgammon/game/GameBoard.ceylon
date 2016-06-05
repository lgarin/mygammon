import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
final class GameBoard() {

	shared Integer totalPointCount = 26;
	
	shared Integer whiteGraveyardPosition = totalPointCount - 1;
	shared Integer whiteHomePosition = 0;
	
	shared Integer blackGraveyardPosition = 0;
	shared Integer blackHomePosition = totalPointCount - 1;

	class BoardPoint(shared Integer position) {
		ArrayList<CheckerColor> checkers = ArrayList<CheckerColor>();
		
		shared void pushChecker(CheckerColor color) => checkers.push(color);
		shared CheckerColor? popChecker() => checkers.pop();
		shared Boolean hasChecker(CheckerColor color) => checkers.any(color.equals);
		shared Integer countCheckers(CheckerColor color) => checkers.count(color.equals);
	}

	ArrayList<BoardPoint> points = ArrayList<BoardPoint>(totalPointCount);
	for (i in 0:totalPointCount) {
		points.add(BoardPoint(i));
	}
	
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

	shared Boolean putNewCheckers(Integer position, CheckerColor color, Integer count) {
		if (exists boardPoint = points[position]) {
			for (i in 0:count) {
				boardPoint.pushChecker(color);
			}
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
	
	Boolean hasChecker(Integer position, CheckerColor color) {
		if (exists boardPoint = points[position]) {
			return boardPoint.hasChecker(color);
		} else {
			return false;
		}
	}
	
	shared Boolean hasCheckerInGraveyard(CheckerColor color) => hasChecker(graveyardPosition(color), color);
	
	Range<Integer> playRange(CheckerColor color) {
		switch (color)
		case (white) { return 7..23; }
		case (black) { return 1..17; }
	}
	
	shared Boolean hasCheckersOutsideHomeArea(CheckerColor color) {
		return playRange(color).any((Integer element) => hasChecker(element, color));
	}
	
	shared Boolean moveChecker(Integer sourcePosition, Integer targetPosition) {
		if (exists sourcePoint = points[sourcePosition], exists targetPoint = points[targetPosition]) {
			if (exists checker = sourcePoint.popChecker()) {
				targetPoint.pushChecker(checker);
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared Integer distance(Integer sourcePosition, Integer targetPosition) => (targetPosition - sourcePosition).magnitude;
}

class GameBoardTest() {
	
	value board = GameBoard();
	
	test
	shared void emptyBoardHasNoChecker() {
		for (i in 0:board.totalPointCount) {
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
		assert (board.graveyardPosition(black) == board.blackGraveyardPosition);
		assert (board.graveyardPosition(white) == board.whiteGraveyardPosition);
	}
	
	test
	shared void testHomePosition() {
		assert (board.homePosition(black) == board.blackHomePosition);
		assert (board.homePosition(white) == board.whiteHomePosition);
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
	shared void cannotMoveFromPositionWithoutChecker() {
		value result = board.moveChecker(1, 2);
		assert (!result);
	}
	
	test
	shared void moveCheckerToFreePosition() {
		board.putNewCheckers(2, white, 1);
		value result = board.moveChecker(2, 22);
		assert (result);
		assert (board.countCheckers(2, white) == 0);
		assert (board.countCheckers(22, white) == 1);
	}
	
	test
	shared void moveCheckerToOccupiedPosition() {
		board.putNewCheckers(2, white, 1);
		board.putNewCheckers(22, black, 1);
		value result = board.moveChecker(2, 22);
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
}
