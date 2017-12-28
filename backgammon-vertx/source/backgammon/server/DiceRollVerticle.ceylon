import backgammon.server.bus {
	DiceRollEventBus
}
import backgammon.server.dice {
	DiceRoller
}
import io.vertx.ceylon.core {
	Verticle
}
import backgammon.shared {
	NewRollMessage
}

final class DiceRollVerticle() extends Verticle() {
	
	shared actual void start() {
		value diceRoller = DiceRoller();
		value rollEventBus = DiceRollEventBus(vertx);
		
		rollEventBus.registerConsumer((request) {
			value roll = diceRoller.roll();
			return NewRollMessage(request.matchId, roll);
		});
	}
}