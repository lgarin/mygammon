import ceylon.collection {
	ArrayList
}
import ceylon.test {

	test
}

shared final class DiceRoll(shared Integer firstValue, shared Integer secondValue) {
	
	ArrayList<Integer> values = ArrayList<Integer>(4);
	
	shared Boolean isPair => firstValue == secondValue;
	
	values.add(firstValue);
	values.add(secondValue);
	
	if (isPair) {
		values.add(firstValue);
		values.add(secondValue);
	}
	
	shared List<Integer> remainingValues => values;
	
	shared Boolean useValue(Integer diceValue) => values.removeFirst(diceValue);
	
	shared Boolean hasValue(Integer diceValue) => values.contains(diceValue);
}

class DiceRollTest() {
	
	test
	shared void checkNormalRoll() {
		value roll = DiceRoll(3, 4);
		assert (roll.remainingValues.size == 2);
		assert (!roll.hasValue(1));
		assert (!roll.hasValue(2));
		assert (roll.hasValue(3));
		assert (roll.hasValue(4));
		assert (!roll.hasValue(5));
		assert (!roll.hasValue(6));
	}
	
	test
	shared void checkPairRoll() {
		value roll = DiceRoll(3, 3);
		assert (roll.remainingValues.size == 4);
		assert (roll.isPair);
		assert (roll.hasValue(3));
		assert (roll.remainingValues.every((Integer element) => element == 3));
	}
	
	test
	shared void useValueRemovesValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValue(3);
		assert (result);
		assert (!roll.hasValue(3));
	}
	
	test
	shared void usePairValueRemovesOnly1Value() {
		value roll = DiceRoll(3, 3);
		value result = roll.useValue(3);
		assert (result);
		assert (roll.hasValue(3));
	}
	
	test
	shared void cannotRemoveNonExistantValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValue(5);
		assert (!result);
	}
}