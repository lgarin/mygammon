import ceylon.json {
	JsonObject=Object
}
import ceylon.time {
	Instant,
	Duration
}
final class PlayerLogin(shared String name, shared Integer count, shared Instant last, shared Instant nextCredit) extends Object() {
	shared JsonObject toJson() => JsonObject {"name" -> name, "count" -> count, "last" -> last.millisecondsOfEpoch, "nextCredit" -> nextCredit.millisecondsOfEpoch};
	
	shared actual Boolean equals(Object that) {
		if (is PlayerLogin that) {
			return name==that.name && 
				count==that.count && 
				last==that.last && 
				nextCredit==that.nextCredit;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		return name.hash;
	}
	
	shared Boolean mustCredit(Instant timestamp, Duration balanceIncreaseDelay) => timestamp.plus(balanceIncreaseDelay) >= nextCredit;
	
	shared PlayerLogin renew(Instant timestamp, Duration balanceIncreaseDelay) {
		if (mustCredit(timestamp, balanceIncreaseDelay)) {
			return PlayerLogin(name, count + 1, timestamp, timestamp.plus(balanceIncreaseDelay));
		} else {
			return PlayerLogin(name, count + 1, timestamp, nextCredit);
		}
	}
}
PlayerLogin parsePlayerLogin(JsonObject json) => PlayerLogin(json.getString("name"), json.getInteger("count"), Instant(json.getInteger("last")), Instant(json.getInteger("nextCredit")));