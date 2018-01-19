import backgammon.shared {
	PlayerStatistic,
	PlayerId,
	PlayerInfo
}

final class PlayerRosterRecord(shared PlayerInfo playerInfo, shared PlayerLogin login, shared PlayerStatistic stat) extends Object() {
	
	shared PlayerId id = PlayerId(playerInfo.id);
	
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
