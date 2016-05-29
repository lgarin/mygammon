import ceylon.collection {
	ArrayList
}
class GameBoard() {

	value totalCheckerCount = 40;
	value totalPointCount = 26;
	
	shared Integer whiteGraveyardIndex = totalPointCount - 1;
	shared Integer whiteHomeIndex = 0;
	
	shared Integer blackGraveyardIndex = 0;
	shared Integer blackHomeIndex = totalPointCount - 1;

	abstract class BoardChecker() of WhiteChecker | BlackChecker {}
	class BlackChecker() extends BoardChecker() {}
	class WhiteChecker() extends BoardChecker() {}

	class BoardPoint(shared Integer position) {
		ArrayList<BoardChecker> checkers = ArrayList<BoardChecker>(totalCheckerCount / 2);
		
		shared void addChecker(BoardChecker checker) => checkers.push(checker);
	}

	ArrayList<BoardPoint> points = ArrayList<BoardPoint>(totalPointCount);
	for (i in 0:totalPointCount) {
		points.add(BoardPoint(i));
	}
	
	shared Boolean putWhiteChecker(Integer position, Integer count) {
		return doPutChecker(position, count, WhiteChecker);
	}
	
	shared Boolean putBlackChecker(Integer position, Integer count) {
		return doPutChecker(position, count, BlackChecker);
	}
	
	Boolean doPutChecker(Integer position, Integer count, BoardChecker() checkerConstructor) {
		if (position < 0 || position >= totalPointCount) {
			return false;
		} else if (exists boardPoint = points[position]) {
			for (i in 0:count) {
				boardPoint.addChecker(checkerConstructor());
			}
			return true;
		} else {
			return false;
		}
	}
}

