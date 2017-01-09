import backgammon.shared {
	PlayerStatistic,
	parsePlayerStatistic,
	PlayerId,
	parsePlayerId
}

import ceylon.json {
	JsonObject=Object
}
final class PlayerRosterRecord(shared PlayerId id, shared PlayerLogin login, shared PlayerStatistic stat) extends Object() {
	
	shared JsonObject toJson() => JsonObject {"id" -> id.toJson(), "login" -> login.toJson(), "stat" -> stat.toJson()};
	
	shared actual Boolean equals(Object that) {
		if (is PlayerRosterRecord that) {
			return id==that.id && 
				login==that.login && 
					stat==that.stat;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash = id.hash;
}

PlayerRosterRecord parsePlayerRosterRecord(JsonObject json) => PlayerRosterRecord(parsePlayerId(json.getString("id")), parsePlayerLogin(json.getObject("login")), parsePlayerStatistic(json.getObject("stat")));