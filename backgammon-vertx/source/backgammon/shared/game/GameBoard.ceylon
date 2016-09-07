import ceylon.collection {
	ArrayList
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

	value whiteOutsideRange = whiteGraveyardPosition..7;
	value blackOutsideRange = blackGraveyardPosition..18;
	
	value whitePlayRange = whiteGraveyardPosition..whiteHomePosition + 1;
	value blackPlayRange = blackGraveyardPosition..blackHomePosition - 1;

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
	
	shared Range<Integer> outsideRange(CheckerColor color) {
		switch (color)
		case (white) { return whiteOutsideRange; }
		case (black) { return blackOutsideRange; }
	}
	
	shared Range<Integer> playRange(CheckerColor color) {
		switch (color)
		case (white) { return whitePlayRange; }
		case (black) { return blackPlayRange; }
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

	shared Boolean hasCheckersOutside(CheckerColor color) {
		return outsideRange(color).any((element) => hasChecker(element, color));
	}
	
	shared Integer countCheckersInPlay(CheckerColor color) {
		return playRange(color).fold(0)((partial, position) => countCheckers(position, color) + partial);
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