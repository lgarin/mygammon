import ceylon.collection {
	ArrayList
}

shared final class DiceRoll(shared Integer firstValue, shared Integer secondValue) extends Object() {
	
	shared Boolean isPair => firstValue == secondValue && firstValue > 0;
	
	shared Boolean isJoker => firstValue < 0 && secondValue < 0;
	
	value values = ArrayList<Integer>(4);
	
	values.add(firstValue);
	values.add(secondValue);
	
	if (isPair) {
		values.add(firstValue);
		values.add(secondValue);
	}
	
	function isInRange(Integer diceValue) => diceValue >= 1 && diceValue <= 6; 
	
	shared Boolean valid => isInRange(firstValue) && isInRange(secondValue);
	
	shared Integer dicePoints => isPair then firstValue * 4 else firstValue + secondValue;
	
	shared Integer getValue(CheckerColor color) {
		return switch (color)
			case (black) firstValue
			case (white) secondValue;
	}
	
	shared CheckerColor adaptColor(CheckerColor color) => isJoker then color.oppositeColor else color; 
	
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
	
	shared [Integer*] remainingValues => values.sequence();
	
	function minValueAtLeast(Integer pointValue) => min(values.select((element) => element >= pointValue));

	shared Integer? useValueAtLeast(Integer pointValue) {
		if (exists result = minValueAtLeast(pointValue), values.removeLast(result)) {
			return result;
		}
		return null;
	}
	
	function maxValueAtMost(Integer pointValue) => max(values.select((element) => element <= pointValue));
	
	shared Integer? useValueAtMost(Integer pointValue) {
		if (exists result = maxValueAtMost(pointValue), values.removeLast(result)) {
			return result;
		}
		return null;
	}
	
	shared Integer? maxRemainingValue => max(values);
	
	shared Integer? minRemainingValue => min(values);
	
	shared Boolean hasRemainingValue(Integer diceValue) => values.contains(diceValue);
	
	shared Boolean addRemainingValue(Integer diceValue) {
		if (isPair) {
			if (diceValue != firstValue) {
				return false;
			} else if (values.size > 4) {
				return false;
			}
		} else {
			if (diceValue != firstValue && diceValue != secondValue) {
				return false;
			} else if (values.contains(diceValue)) {
				return false;
			}
		}
		
		values.add(diceValue);
		return true;
	}
	
	shared Boolean resetRemainingValues({Integer*} newValues) {
		if (isPair) {
			if (newValues.size > 4) {
				return false;
			} else if (newValues.any((element) => element != firstValue)) {
				return false;
			}
		} else {
			if (newValues.size > 2) {
				return false;
			} else if (newValues.any((element) => element != firstValue && element != secondValue)) {
				return false;
			}
		}
		
		values.clear();
		values.addAll(newValues);
		return true;
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