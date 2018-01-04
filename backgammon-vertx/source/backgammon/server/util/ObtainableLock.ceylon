import java.util.concurrent.locks {
	ReentrantLock
}
import ceylon.logging {

	logger
}
import java.util.concurrent {

	TimeUnit
}
import java.lang {

	InterruptedException
}

shared final class ObtainableLock(String name) satisfies Obtainable {
	value lock = ReentrantLock();
	value condition = lock.newCondition();
	
	shared Boolean locked => lock.locked;
	
	shared actual void obtain() {
		while (true) {
			try {
				lock.tryLock(1, TimeUnit.seconds);
				return;
			} catch (InterruptedException e) {
				logger(`package`).warn("Waiting for lock : ``name``");
			}
		}
	}
	
	shared actual void release(Throwable? error) {
		lock.unlock();
	}
	
	shared void waitSignal() {
		while (true) {
			try {
				condition.await(1, TimeUnit.seconds);
				return;
			} catch (InterruptedException e) {
				logger(`package`).warn("Waiting for condition : ``name``");
			}
		}
	}
	
	shared void signalAll() {
		condition.signalAll();
	}
}
