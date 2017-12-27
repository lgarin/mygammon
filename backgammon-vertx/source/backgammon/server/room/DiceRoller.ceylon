import backgammon.shared.game {
	DiceRoll
}

import java.security {
	SecureRandom
}

shared final class DiceRoller() {
	
	variable SecureRandom? random = null;
	
	SecureRandom lazyRandom => random else (random = SecureRandom());

	Integer rollOne() => lazyRandom.nextInt(5) + 1;
	
	shared DiceRoll roll() => DiceRoll(rollOne(), rollOne());
}
