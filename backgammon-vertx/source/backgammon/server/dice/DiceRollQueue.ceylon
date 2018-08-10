import backgammon.shared.game {

	DiceRoll
}
import backgammon.server.util {

	ObtainableLock
}
import ceylon.collection {

	LinkedList
}
shared final class DiceRollQueue(String id) {
	
	value queue = LinkedList<DiceRoll>();
	value lock = ObtainableLock("DiceRollQueue ``id``");
	
	shared DiceRoll takeNextRoll() {
		try (lock) {
			while (true) {
				if (exists roll = queue.accept()) {
					lock.signalAll();
					return roll;
				} else {
					lock.waitSignal();
				}
			}
		}
	}
	
	shared Boolean needNewRoll() {
		try (lock) {
			return queue.empty;
		}
	}
	
	shared void setNextRoll(DiceRoll roll) {
		try (lock) {
			queue.add(roll);
			lock.signalAll();
		}
	}
}