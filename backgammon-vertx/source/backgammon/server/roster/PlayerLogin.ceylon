import ceylon.json {
	JsonObject=Object
}
import ceylon.time {
	Instant,
	Duration
}
final class PlayerLogin(shared Integer count, shared Instant last, shared Instant nextCredit) extends Object() {
	shared JsonObject toJson() => JsonObject {"count" -> count, "last" -> last.millisecondsOfEpoch, "nextCredit" -> nextCredit.millisecondsOfEpoch};
	
	shared actual Boolean equals(Object that) {
		if (is PlayerLogin that) {
			return count==that.count && 
				last==that.last && 
				nextCredit==that.nextCredit;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		return count.hash;
	}
	
	shared Boolean mustCredit(Instant timestamp) => timestamp >= nextCredit;
	
	shared PlayerLogin renew(Instant timestamp, Duration balanceIncreaseDelay) {
		if (mustCredit(timestamp)) {
			return PlayerLogin(count + 1, timestamp, timestamp.plus(balanceIncreaseDelay));
		} else {
			return PlayerLogin(count + 1, timestamp, nextCredit);
		}
	}
}
PlayerLogin parsePlayerLogin(JsonObject json) => PlayerLogin(json.getInteger("count"), Instant(json.getInteger("last")), Instant(json.getInteger("nextCredit")));