import ceylon.test {
	test
}
import backgammon.shared.game {
	DiceRoll
}

class DiceRollTest() {
	
	test
	shared void checkNormalRoll() {
		value roll = DiceRoll(3, 4);
		assert (roll.remainingValues.size == 2);
		assert (!roll.hasRemainingValue(1));
		assert (!roll.hasRemainingValue(2));
		assert (roll.hasRemainingValue(3));
		assert (roll.hasRemainingValue(4));
		assert (!roll.hasRemainingValue(5));
		assert (!roll.hasRemainingValue(6));
	}
	
	test
	shared void checkPairRoll() {
		value roll = DiceRoll(3, 3);
		assert (roll.remainingValues.size == 4);
		assert (roll.isPair);
		assert (roll.hasRemainingValue(3));
		assert (roll.remainingValues.every((element) => element == 3));
	}
	
	test
	shared void useValueRemovesExactValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(3);
		assert (exists result, result == 3);
		assert (!roll.hasRemainingValue(3));
	}
	
	test
	shared void usePairValueRemovesOnlyFirstValue() {
		value roll = DiceRoll(3, 3);
		value result = roll.useValueAtLeast(3);
		assert (exists result, result == 3);
		assert (roll.hasRemainingValue(3));
	}
	
	test
	shared void cannotRemoveTooLargeValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(5);
		assert (!exists result);
	}
	
	test
	shared void useValueRemovesMinValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(2);
		assert (exists result, result == 3);
		assert (roll.hasRemainingValue(4));
	}
}