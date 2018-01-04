import backgammon.shared.game {
	DiceRoll
}

import java.security {
	SecureRandom
}
import backgammon.server.util {

	ObtainableLock
}

shared final class DiceRoller() {
	
	value lock = ObtainableLock("DiceRoller"); 
	
	variable SecureRandom? random = null;
	
	value lazyRandom => random else (random = SecureRandom());
	
	function rollOne() => lazyRandom.nextInt(5) + 1;
	
	shared DiceRoll roll() {
		try (lock) {
			return DiceRoll(rollOne(), rollOne());
		}
	}
}
