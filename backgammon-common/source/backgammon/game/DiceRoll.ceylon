import ceylon.collection {
	ArrayList
}
import ceylon.test {

	test
}

shared final class DiceRoll(shared Integer firstValue, shared Integer secondValue) {
	
	ArrayList<Integer> values = ArrayList<Integer>(4);
	
	shared Boolean isPair => firstValue == secondValue;
	
	shared Integer getValue(CheckerColor color) {
		switch (color)
		case (black) {
			return firstValue;  // TODO black is first player
		}
		case (white) {
			return secondValue;
		}
	}
	
	values.add(firstValue);
	values.add(secondValue);
	
	if (isPair) {
		values.add(firstValue);
		values.add(secondValue);
	}
	
	shared List<Integer> remainingValues => values;

	shared Integer? useValueAtLeast(Integer pointValue) {
		if (values.removeFirst(pointValue)) {
			return pointValue;
		} else if (nonempty currentValues = values.sequence()) {
			value maxValue = max(currentValues);
			if (maxValue >= pointValue && values.removeFirst(maxValue)) {
				return maxValue;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	shared Integer? maxValue => max(values);
	
	shared Boolean hasValue(Integer diceValue) => values.contains(diceValue);
	
	shared DiceRoll add(Integer diceValue) {
		value copy = DiceRoll(firstValue, secondValue);
		copy.values.clear();
		copy.values.addAll(remainingValues);
		copy.values.add(diceValue);
		return copy;
	}
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
	shared void useValueRemovesExactValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(3);
		assert (exists result, result == 3);
		assert (!roll.hasValue(3));
	}
	
	test
	shared void usePairValueRemovesOnlyFirstValue() {
		value roll = DiceRoll(3, 3);
		value result = roll.useValueAtLeast(3);
		assert (exists result, result == 3);
		assert (roll.hasValue(3));
	}
	
	test
	shared void cannotRemoveTooLargeValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(5);
		assert (!exists result);
	}
	
	test
	shared void useValueRemovesMaxValue() {
		value roll = DiceRoll(3, 4);
		value result = roll.useValueAtLeast(2);
		assert (exists result, result == 4);
		assert (roll.hasValue(3));
	}
}