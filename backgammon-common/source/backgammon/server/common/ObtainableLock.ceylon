import java.util.concurrent.locks {

	ReentrantLock
}
import ceylon.test {

	test
}

shared final class ObtainableLock() satisfies Obtainable {
	value lock = ReentrantLock();
	
	shared Boolean locked => lock.locked;
	
	shared actual void obtain() {
		lock.lock();
	}
	
	shared actual void release(Throwable? error) {
		lock.unlock();
	}
}

class ObtainableLockTest() {
	value lock = ObtainableLock();
	
	test
	shared void lockReleasesLock() {
		try (lock) {
			assert (lock.locked);
		}
		assert (!lock.locked);
	}
	
	test
	shared void lockPropagatesException() {
		try (lock) {
			throw Exception("test");
		} catch (Exception e) {
			assert (e.message == "test");
		}
	}
}