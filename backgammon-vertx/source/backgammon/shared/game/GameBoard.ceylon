import ceylon.collection {
	ArrayList
}

final class BoardPoint(shared Integer position) {
	variable Integer whiteCount = 0;
	variable Integer blackCount = 0;
	
	shared void putChecker(CheckerColor color, Integer count) {
		assert (count >= 0);
		switch (color)
		case (black) {blackCount += count;}
		case (white) {whiteCount += count;}
	}
	
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

shared Integer boardPointCount = 24;

shared Integer whiteHomePosition = 0;
shared Integer whiteGraveyardPosition = boardPointCount + 1;
shared Integer whiteStartPosition = boardPointCount + 2;

shared Integer blackStartPosition = -1;
shared Integer blackGraveyardPosition = 0;
shared Integer blackHomePosition = boardPointCount + 1;

shared Range<Integer> wholePlayRange = blackStartPosition..whiteStartPosition;

shared final class GameBoard() {

	value whiteOutsideRange = whiteStartPosition..7;
	value blackOutsideRange = blackStartPosition..17;
	
	value whitePlayRange = whiteStartPosition..whiteHomePosition+1;
	value blackPlayRange = blackStartPosition..blackHomePosition-1;

	shared Integer startPosition(CheckerColor color) {
		return switch (color)
		case (white) whiteStartPosition
		case (black) blackStartPosition;
	}

	shared Integer graveyardPosition(CheckerColor color) {
		return switch (color)
			case (white) whiteGraveyardPosition
			case (black) blackGraveyardPosition;
	}
	
	shared Integer homePosition(CheckerColor color) {
		return switch (color)
			case (white) whiteHomePosition
			case (black) blackHomePosition;
	}
	
	shared Range<Integer> outsideRange(CheckerColor color) {
		return switch (color)
			case (white) whiteOutsideRange
			case (black) blackOutsideRange;
	}
	
	shared Range<Integer> playRange(CheckerColor color) {
		return switch (color)
			case (white) whitePlayRange
			case (black) blackPlayRange;
	}
	
	shared Integer directionSign(CheckerColor color) {
		return switch (color)
			case (white) -1
			case (black) +1;
	}
	
	function positiveTargetRange(CheckerColor color, Integer sourcePosition, Integer maxDistance) {
		switch (color)
		case (white) {
			if (sourcePosition <= whiteHomePosition || sourcePosition > whiteGraveyardPosition) {
				return [];
			}
			value endPosition = sourcePosition - maxDistance;
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
			value endPosition = sourcePosition + maxDistance;
			if (endPosition < blackHomePosition) {  
				return sourcePosition+1..endPosition; 
			} else {
				return sourcePosition+1..blackHomePosition;
			}
		}
	}
	
	function negativeTargetRange(CheckerColor color, Integer sourcePosition, Integer maxDistance) {
		switch (color)
		case (white) {
			if (sourcePosition <= whiteHomePosition || sourcePosition > whiteGraveyardPosition) {
				return [];
			}
			value endPosition = sourcePosition + maxDistance;
			if (endPosition > whiteGraveyardPosition) {  
				return sourcePosition+1..whiteGraveyardPosition; 
			} else {
				return sourcePosition+1..endPosition;
			}
		}
		case (black) {
			if (sourcePosition >= blackHomePosition || sourcePosition < blackGraveyardPosition) {
				return [];
			}
			value endPosition = sourcePosition - maxDistance;
			if (endPosition < blackGraveyardPosition) {  
				return sourcePosition-1..blackGraveyardPosition; 
			} else {
				return sourcePosition-1..endPosition;
			}
		}
	}
	
	shared [Integer*] targetRange(CheckerColor color, Integer sourcePosition, Integer maxDistance) {
		if (maxDistance == 0) {
			return [];
		} else if (sourcePosition == startPosition(color)) {
			return targetRange(color, graveyardPosition(color), maxDistance);
		} else if (maxDistance < 0) {
			return negativeTargetRange(color, sourcePosition, -maxDistance);
		} else {
			return positiveTargetRange(color, sourcePosition, maxDistance);
		}
	}
	
	ArrayList<BoardPoint> points = ArrayList<BoardPoint>(wholePlayRange.size);
	for (i in wholePlayRange) {
		points.add(BoardPoint(i));
	}
	
	function getPoint(Integer position) => points[position + 1];
	
	shared Boolean isInRange(Integer position) {
		return wholePlayRange.contains(position);
	}

	shared Boolean putNewCheckers(Integer position, CheckerColor color, Integer count) {
		if (count < 0) {
			return false;
		} else if (exists boardPoint = getPoint(position)) {
			boardPoint.putChecker(color, count);
			return true;
		} else {
			return false;
		}
	}
	
	shared Integer countCheckers(Integer position, CheckerColor color) {
		if (exists boardPoint = getPoint(position)) {
			return boardPoint.countCheckers(color);
		} else {
			return 0;
		}
	}
	
	function hasChecker(Integer position, CheckerColor color) {
		if (exists boardPoint = getPoint(position)) {
			return boardPoint.hasChecker(color);
		} else {
			return false;
		}
	}
	
	shared Boolean hasCheckerInGraveyard(CheckerColor color) => hasChecker(graveyardPosition(color), color);

	shared Boolean hasCheckersOutside(CheckerColor color) {
		return outsideRange(color).any((element) => hasChecker(element, color));
	}
	
	shared Integer remainingDistance(CheckerColor color) {
		return playRange(color).fold(0)((partial, position) => distance(position, homePosition(color)) * countCheckers(position, color) + partial);
	}
	
	shared Boolean moveChecker(CheckerColor color, Integer sourcePosition, Integer targetPosition) {
		if (exists sourcePoint = getPoint(sourcePosition), exists targetPoint = getPoint(targetPosition)) {
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
	
	shared Integer distance(Integer sourcePosition, Integer targetPosition) {
		if (sourcePosition == whiteStartPosition) {
			return distance(whiteGraveyardPosition, targetPosition);
		} else if (sourcePosition == blackStartPosition) {
			return distance(blackGraveyardPosition, targetPosition);
		} else {
			return (targetPosition - sourcePosition).magnitude;
		}
	}
	
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