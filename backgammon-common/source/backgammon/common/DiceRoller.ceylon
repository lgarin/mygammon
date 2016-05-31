import java.security {

	SecureRandom
}
import backgammon.game {

	DiceRoll
}
class DiceRoller() {
	
	value random = SecureRandom();

	Integer rollOne() => random.nextInt(5) + 1;
	
	shared DiceRoll roll() => DiceRoll(rollOne(), rollOne());
}