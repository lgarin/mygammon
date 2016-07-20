import ceylon.test {

	test
}
shared abstract class CheckerColor() of black | white {
	shared formal CheckerColor oppositeColor;
	shared formal String name;
}
shared object black extends CheckerColor() {
 	oppositeColor => white;
 	name => "black";
}
shared object white extends CheckerColor() {
	oppositeColor => black;
	name => "white";
}

shared CheckerColor player1Color = black;
shared CheckerColor player2Color = white;

shared CheckerColor parseCheckerColor(String name) {
	if (name == white.name) {
		return white;
	} else if (name == black.name) {
		return black;
	} else {
		throw Exception("Invalid color: ``name``");
	}
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