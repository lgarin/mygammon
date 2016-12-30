import ceylon.json {

	JsonObject=Object
}
shared final class MatchBalance(shared Integer playerBet, shared Integer matchPot, shared Integer player1Balance, shared Integer player2Balance) extends Object() {
	
	function balanceDelta(Boolean bet, Boolean winner) => (if (winner) then matchPot else 0) - (if (bet) then playerBet else 0);
	shared Integer currentPlayer1Balance(Boolean bet, Boolean winner) => player1Balance + balanceDelta(bet, winner);
	shared Integer currentPlayer2Balance(Boolean bet, Boolean winner) => player2Balance + balanceDelta(bet, winner);
	
	shared actual Boolean equals(Object that) {
		if (is MatchBalance that) {
			return playerBet==that.playerBet && 
				matchPot==that.matchPot && 
				player1Balance==that.player1Balance && 
				player2Balance==that.player2Balance;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + playerBet;
		hash = 31*hash + matchPot;
		hash = 31*hash + player1Balance;
		hash = 31*hash + player2Balance;
		return hash;
	}
	
	shared JsonObject toJson() => JsonObject {"playerBet" -> playerBet, "matchPot" -> matchPot, "player1Balance" -> player1Balance, "player2Balance" -> player2Balance};
	
	string => toJson().string;
}

shared MatchBalance parseMatchBalance(JsonObject json) => MatchBalance(json.getInteger("playerBet"), json.getInteger("matchPot"), json.getInteger("player1Balance"), json.getInteger("player2Balance"));
