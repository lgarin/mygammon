import backgammon.shared.game {

	DiceRoll
}
import backgammon.server.util {

	ObtainableLock
}
shared final class DiceRollQueue(String id) {
	
	variable DiceRoll? nextRoll = null;
	value nextRollLock = ObtainableLock("DiceRoll ``id``");
	
	shared DiceRoll takeNextRoll() {
		try (nextRollLock) {
			while (true) {
				if (exists roll = nextRoll) {
					nextRoll = null;
					nextRollLock.signalAll();
					return roll;
				} else {
					nextRollLock.waitSignal();
				}
			}
		}
	}
	
	shared void waitForNewRoll() {
		try (nextRollLock) {
			while (true) {
				if (nextRoll is Null) {
					nextRollLock.waitSignal();
				}
			}
		}
	}
	
	shared Boolean needNewRoll() {
		try (nextRollLock) {
			return nextRoll is Null;
		}
	}
	
	shared void setNextRoll(DiceRoll roll) {
		try (nextRollLock) {
			while (true) {
				if (nextRoll is Null) {
					nextRoll = roll;
					nextRollLock.signalAll();
					return;
				} else {
					nextRollLock.waitSignal();
				}
			}
		}
	}
}