import ceylon.collection {
	ArrayList
}

shared final class DiceRoll(shared Integer firstValue, shared Integer secondValue) extends Object() {
	
	shared Boolean isPair => firstValue == secondValue;
	
	value values = ArrayList<Integer>(4);
	
	values.add(firstValue);
	values.add(secondValue);
	
	if (isPair) {
		values.add(firstValue);
		values.add(secondValue);
	}
	
	shared Integer getValue(CheckerColor color) {
		switch (color)
		case (black) {
			return firstValue;  // TODO black is first player
		}
		case (white) {
			return secondValue;
		}
	}
	
	shared [<Integer->Boolean>*] state {
		if (isPair) {
			if (values.size > 3) {
				return [firstValue->true, secondValue->true, firstValue->true, secondValue->true];
			} else if (values.size > 2) {
				return [firstValue->true, secondValue->true, firstValue->true, secondValue->false];
			} else if (values.size > 1) {
				return [firstValue->true, secondValue->true, firstValue->false, secondValue->false];
			} else if (values.size > 0) {
				return [firstValue->true, secondValue->false, firstValue->false, secondValue->false];
			} else {
				return [firstValue->false, secondValue->false, firstValue->false, secondValue->false];
			}
		} else {
			return [firstValue->values.contains(firstValue), secondValue->values.contains(secondValue)];
		}
	}
	
	shared List<Integer> remainingValues => values;
	
	function minValueAtLeast(Integer pointValue) => min(values.select((element) => element >= pointValue));

	shared Integer? useValueAtLeast(Integer pointValue) {
		if (exists result = minValueAtLeast(pointValue), values.removeLast(result)) {
			return result;
		}
		return null;
	}
	
	shared Integer? maxRemainingValue => max(values);
	
	shared Boolean hasRemainingValue(Integer diceValue) => values.contains(diceValue);
	
	shared void addRemainingValue(Integer diceValue) {
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