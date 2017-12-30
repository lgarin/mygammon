

import ceylon.test {
	test
}
import backgammon.server.dice {

	DiceRoller
}

class DiceRollerTest() {
	
	value diceRoller = DiceRoller();
	
	test
	shared void rollIsBetween1and6() {
		value roll = diceRoller.roll();
		assert (roll.firstValue <= 6);
		assert (roll.firstValue >= 1);
		assert (roll.secondValue <= 6);
		assert (roll.secondValue >= 1);
	}
}