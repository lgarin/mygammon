shared final class MatchBet(shared Integer playerBet, shared Integer matchPot) extends Object() {
	shared actual Boolean equals(Object that) {
		if (is MatchBet that) {
			return playerBet==that.playerBet && 
				matchPot==that.matchPot;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + playerBet;
		hash = 31*hash + matchPot;
		return hash;
	}
}