import backgammon.server.util {
	ObtainableLock
}

import ceylon.test {
	test
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