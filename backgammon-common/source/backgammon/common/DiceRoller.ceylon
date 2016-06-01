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
	
	value random = SecureRandom();

	Integer rollOne() => random.nextInt(5) + 1;
	
	shared DiceRoll roll() => DiceRoll(rollOne(), rollOne());
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