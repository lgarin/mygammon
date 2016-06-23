import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}
import ceylon.buffer.base {

	base64StringStandard
}
import ceylon.buffer.codec {

	strict
}
final class GameBoard() {

	shared Integer totalPointCount = 26;
	
	shared Integer whiteGraveyardPosition = totalPointCount - 1;
	shared Integer whiteHomePosition = 0;
	
	shared Integer blackGraveyardPosition = 0;
	shared Integer blackHomePosition = totalPointCount - 1;

	class BoardPoint(shared Integer position) {
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
	
	function playRange(CheckerColor color) {
		switch (color)
		case (white) { return 7..23; }
		case (black) { return 1..17; }
	}
	
	shared Range<Integer> positionRange(CheckerColor color) {
		switch (color)
		case (white) { return 1..25; }
		case (black) { return 25..1; }
	}
	
	shared Integer directionSign(CheckerColor color) {
		
		switch (color)
		case (white) { return 1; }
		case (black) { return -1; }
	}
	
	shared Boolean isInRange(Integer position) {
		return 0 <= position < totalPointCount; 
	}
	
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
	
	function encodeState(CheckerColor color) {
		return {for (p in points) p.countCheckers(color).byte};
	}
	
	void decodeState(CheckerColor color, Iterator<Byte> data) {
		for (p in points) {
			if (is Byte count = data.next()) {
				p.resetChecker(color, count.unsigned);
			} else {
				p.resetChecker(color, 0);
			}
		}
	}
	
	shared String state => base64StringStandard.encode(encodeState(black).chain(encodeState(white)));
	
	assign state {
		value data = base64StringStandard.decode(state, strict).iterator();
		decodeState(black, data);
		decodeState(white, data);
	}
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
	shared void initialState() {
		value result = board.state;
		assert (result == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==");
	}
	
	test
	shared void setStateWithInitialState() {
		board.state = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==";
		for (p in 0:25) {
			value result1 = board.countCheckers(p, black);
			assert (result1 == 0);
			value result2 = board.countCheckers(p, white);
			assert (result2 == 0);
		}
	}
	
	test
	shared void stateWithOneBlackChecker() {
		board.putNewCheckers(0, black, 1);
		value result = board.state;
		assert (result == "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==");
	}
	
	test
	shared void initStateWithOneBlackChecker() {
		board.state = "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==";
		value result = board.countCheckers(0, black);
		assert (result == 1);
	}
	
	test
	shared void stateWithOneWhiteChecker() {
		board.putNewCheckers(0, white, 1);
		value result = board.state;
		assert (result == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==");
	}
	
	test
	shared void initStateWithOneWhiteChecker() {
		board.state = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==";
		value result = board.countCheckers(0, white);
		assert (result == 1);
	}
}
