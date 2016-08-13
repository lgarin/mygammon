import ceylon.collection {
	ArrayList
}

shared final class DiceRoll(shared Integer firstValue, shared Integer secondValue) extends Object() {
	
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
	
	shared Integer? minValueAtLeast(Integer pointValue) {
		return min(values.select((Integer element) => element >= pointValue));
	}

	shared Integer? useValueAtLeast(Integer pointValue) {
		if (exists result = minValueAtLeast(pointValue), values.removeLast(result)) {
			return result;
		}
		return null;
	}
	
	shared Integer? maxValue => max(values);
	
	shared Boolean hasValue(Integer diceValue) => values.contains(diceValue);
	
	shared void add(Integer diceValue) {
		values.add(diceValue);
	}
	
	shared actual Boolean equals(Object that) {
		if (is DiceRoll that) {
			return firstValue==that.firstValue && 
				secondValue==that.secondValue && 
				values==that.values;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + firstValue;
		hash = 31*hash + secondValue;
		hash = 31*hash + values.hash;
		return hash;
	}
	
	string = "``firstValue````values.contains(firstValue) then "+" else "-"``:``secondValue````values.contains(secondValue) then "+" else "-"``";
}