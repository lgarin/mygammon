import java.security {

	SecureRandom
}
import backgammon.game {

	DiceRoll
}
import ceylon.test {

	test
}
final class DiceRoller() {
	
	variable SecureRandom? random = null;
	
	SecureRandom lazyRandom => random else (random = SecureRandom());

	Integer rollOne() => lazyRandom.nextInt(5) + 1;
	
	shared DiceRoll roll() => DiceRoll(rollOne(), rollOne());
	
	shared DiceRoll rollUntilNotPair() {
		while (true) {
			value currentRoll = roll();
			if (!currentRoll.isPair) {
				return currentRoll;
			}
		}
	}
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