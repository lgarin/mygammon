import ceylon.time {
	Duration
}
import ceylon.time.base {
	milliseconds
}

shared object world {
	// TODO use configuration
	shared Duration maximumGameJoinTime = Duration(30 * milliseconds.perSecond);
	
}
