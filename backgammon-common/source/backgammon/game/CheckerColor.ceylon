import ceylon.test {

	test
}
shared abstract class CheckerColor() of black | white {
	shared formal CheckerColor oppositeColor;
}
shared object black extends CheckerColor() {
 	oppositeColor => white;
}
shared object white extends CheckerColor() {
	oppositeColor => black;
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
}