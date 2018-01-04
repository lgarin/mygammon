import ceylon.logging {
	logger
}

import java.util.concurrent {
	TimeUnit
}
import java.util.concurrent.locks {
	ReentrantLock
}

shared final class ObtainableLock(String name) satisfies Obtainable {
	value lock = ReentrantLock();
	value condition = lock.newCondition();
	
	shared Boolean locked => lock.locked;
	
	shared actual void obtain() {
		while (!lock.tryLock(1, TimeUnit.seconds)) {
			logger(`package`).warn("Waiting for lock : ``name``");
		}
	}
	
	shared actual void release(Throwable? error) {
		lock.unlock();
	}
	
	shared void waitSignal() {
		while (!condition.await(1, TimeUnit.seconds)) {
			logger(`package`).warn("Waiting for condition : ``name``");
		}
	}
	
	shared void signalAll() {
		condition.signalAll();
	}
}
