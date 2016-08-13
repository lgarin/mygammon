import ceylon.test {
	test
}
import backgammon.shared.game {
	white,
	parseCheckerColor,
	black
}

class CheckerColorTest() {
	
	test
	shared void oppositeOfWhiteIsBlack() {
		value color = white.oppositeColor;
		assert (color == black);
	}
	
	test
	shared void oppositeOfBlackIsWhite() {
		value color = black.oppositeColor;
		assert (color == white);
	}
	
	test
	shared void parseBlackColor() {
		value color = parseCheckerColor("black");
		assert (color == black);
	}
	
	test
	shared void parseWhiteColor() {
		value color = parseCheckerColor("white");
		assert (color == white);
	}
	
	test
	shared void parseUnknownColor() {
		try {
			parseCheckerColor("xyz");
		} catch (Exception e) {
			assert (e.message == "Invalid color: xyz");
		}
	}
}