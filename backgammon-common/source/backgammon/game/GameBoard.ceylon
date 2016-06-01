import ceylon.collection {
	ArrayList
}
import ceylon.language.meta.model {
	Class
}
import ceylon.test {
	test
}
final class GameBoard() {

	shared Integer totalPointCount = 26;
	
	shared Integer whiteGraveyardIndex = totalPointCount - 1;
	shared Integer whiteHomeIndex = 0;
	
	shared Integer blackGraveyardIndex = 0;
	shared Integer blackHomeIndex = totalPointCount - 1;

	class BoardPoint(shared Integer position) {
		ArrayList<BoardChecker> checkers = ArrayList<BoardChecker>();
		
		shared void pushChecker(BoardChecker checker) => checkers.push(checker);
		
		shared BoardChecker? popChecker() => checkers.pop();
		shared Integer countCheckers(Boolean(BoardChecker) matchFunction) => checkers.count(matchFunction);
	}

	ArrayList<BoardPoint> points = ArrayList<BoardPoint>(totalPointCount);
	for (i in 0:totalPointCount) {
		points.add(BoardPoint(i));
	}
	
	shared Boolean putNewCheckers(Integer position, Class<BoardChecker,[]> type, Integer count) {
		if (exists boardPoint = points[position]) {
			for (i in 0:count) {
				boardPoint.pushChecker(type());
			}
			return true;
		} else {
			return false;
		}
	}
	
	shared Integer countCheckers(Integer position, Class<BoardChecker,[]> type) {
		if (exists boardPoint = points[position]) {
			return boardPoint.countCheckers(type.typeOf);
		} else {
			return 0;
		}
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
}

class GameBoardTest() {
	
	value board = GameBoard();
	
	test
	shared void newBoardHasNoChecker() {
		for (i in 0:board.totalPointCount) {
			assert (board.countCheckers(i, `BoardChecker`) == 0);
		}
	}
	
	test
	shared void addCheckerToFreePosition() {
		value result = board.putNewCheckers(2, `BlackChecker`, 1);
		assert (result);
		assert (board.countCheckers(2, `BlackChecker`) == 1);
	}
	
	test
	shared void addCheckerToOccupiedPosition() {
		board.putNewCheckers(2, `WhiteChecker`, 1);
		value result = board.putNewCheckers(2, `BlackChecker`, 1);
		assert (result);
		assert (board.countCheckers(2, `BoardChecker`) == 2);
		assert (board.countCheckers(2, `BlackChecker`) == 1);
		assert (board.countCheckers(2, `WhiteChecker`) == 1);
	}
	
	test
	shared void cannotMoveFromPositionWithoutChecker() {
		value result = board.moveChecker(1, 2);
		assert (!result);
	}
	
	test
	shared void moveCheckerToFreePosition() {
		board.putNewCheckers(2, `WhiteChecker`, 1);
		value result = board.moveChecker(2, 22);
		assert (result);
		assert (board.countCheckers(2, `WhiteChecker`) == 0);
		assert (board.countCheckers(22, `WhiteChecker`) == 1);
	}
	
	test
	shared void moveCheckerToOccupiedPosition() {
		board.putNewCheckers(2, `WhiteChecker`, 1);
		board.putNewCheckers(22, `BlackChecker`, 1);
		value result = board.moveChecker(2, 22);
		assert (result);
		assert (board.countCheckers(2, `WhiteChecker`) == 0);
		assert (board.countCheckers(22, `WhiteChecker`) == 1);
		assert (board.countCheckers(22, `BlackChecker`) == 1);
	}
}
