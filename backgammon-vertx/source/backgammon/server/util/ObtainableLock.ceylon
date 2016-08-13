import java.util.concurrent.locks {
	ReentrantLock
}

shared final class ObtainableLock() satisfies Obtainable {
	value lock = ReentrantLock();
	
	shared Boolean locked => lock.locked;
	
	shared actual void obtain() {
		lock.lockInterruptibly();
	}
	
	shared actual void release(Throwable? error) {
		lock.unlock();
	}
}
