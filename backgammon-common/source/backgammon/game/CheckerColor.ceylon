import ceylon.test {

	test
}
abstract class CheckerColor() of black | white {
	shared formal CheckerColor oppositeColor;
}
object black extends CheckerColor() {
 	oppositeColor => white;
}
object white extends CheckerColor() {
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