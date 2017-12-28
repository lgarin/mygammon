import backgammon.shared.game {
	DiceRoll
}

import java.security {
	SecureRandom
}

shared final class DiceRoller() {
	
	value random = SecureRandom();
	
	function rollOne() => random.nextInt(5) + 1;
	
	shared DiceRoll roll() => DiceRoll(rollOne(), rollOne());
}
