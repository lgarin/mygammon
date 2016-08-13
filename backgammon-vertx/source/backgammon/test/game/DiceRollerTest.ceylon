import backgammon.server.room {
	DiceRoller
}

import ceylon.test {
	test
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
	
	test
	shared void rollUntilNotPair() {
		value roll = diceRoller.rollUntilNotPair();
		assert (!roll.isPair);
	}
}