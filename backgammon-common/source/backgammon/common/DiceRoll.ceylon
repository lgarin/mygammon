import ceylon.collection {
	ArrayList
}

shared class DiceRoll(shared Integer firstValue, shared Integer secondValue) {

	ArrayList<Integer> values = ArrayList<Integer>(4);

	shared Boolean isPair => firstValue == secondValue;
	
	shared List<Integer> remainingValues => values;
	
	shared Boolean useValue(Integer diceValue) => values.removeFirst(diceValue);
	
	shared Boolean hasValue(Integer diceValue) => values.contains(diceValue);

	values.add(firstValue);
	values.add(secondValue);
	
	if (isPair) {
		values.add(firstValue);
		values.add(secondValue);
	}
}