import ceylon.json {
	JsonObject=Object
}
import ceylon.time {

	Instant
}

shared final class PlayerStatistic(shared Integer balance = 0, shared Integer playedGames = 0, shared Integer wonGames = 0, shared Integer score = 0) extends Object() satisfies Summable<PlayerStatistic> {
	shared Integer winPercentage => if (playedGames > 0) then 100 * wonGames / playedGames else 0;
	shared Integer lostPercentage => if (playedGames > 0) then 100 * (playedGames - wonGames) / playedGames else 0;
	shared JsonObject toJson() => JsonObject {"balance" -> balance, "playedGames" -> playedGames, "wonGames" -> wonGames, "score" -> score};
	shared PlayerStatistic increaseGameCount() => PlayerStatistic(balance, playedGames + 1, wonGames, score);
	shared PlayerStatistic increaseWinCount(Integer winScore) => PlayerStatistic(balance, playedGames, wonGames + 1, score + winScore);
	shared PlayerStatistic updateBalance(Integer delta) => PlayerStatistic(balance + delta, playedGames, wonGames, score);
	
	string => toJson().string;
	shared actual Boolean equals(Object that) {
		if (is PlayerStatistic that) {
			return balance==that.balance && 
				playedGames==that.playedGames && 
				wonGames==that.wonGames && 
				score==that.score;
		} else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + balance;
		hash = 31*hash + playedGames;
		hash = 31*hash + wonGames;
		hash = 31*hash + score;
		return hash;
	}
	
	shared Integer? computeLevel(Integer[] scoreLevels) => scoreLevels.indexed.findLast((index -> limit) => score >= limit)?.key else null;
	
	shared actual PlayerStatistic plus(PlayerStatistic other) => PlayerStatistic(balance + other.balance, playedGames + other.playedGames, wonGames + other.wonGames, score + other.score);
}

shared PlayerStatistic parsePlayerStatistic(JsonObject json) => PlayerStatistic(json.getInteger("balance"), json.getInteger("playedGames"), json.getInteger("wonGames"), json.getInteger("score"));

shared PlayerStatistic? parseNullablePlayerStatistic(JsonObject? json) => if (exists json) then parsePlayerStatistic(json) else null;

shared final class PlayerState(shared PlayerInfo info, shared PlayerStatistic statistic, shared TableId? tableId, shared MatchId? matchId) extends Object() {
	shared JsonObject toJson() => JsonObject {"info" -> info.toJson(), "statistic" -> statistic.toJson(), "tableId" -> tableId?.toJson(), "matchId" -> matchId?.toJson()};
	shared PlayerId playerId => info.playerId;
	shared Boolean isAtTable(TableId otherTableId) => if (exists tableId) then tableId == otherTableId else false;
	shared Boolean isPlayingAtTable(TableId otherTableId) => matchId exists && isAtTable(otherTableId);
	shared PlayerState withTable(TableId? tableId) => PlayerState(info, statistic, tableId, matchId);
	
	string => toJson().string;

	function equalsOrBothNull(Object? object1, Object? object2) {
		if (exists object1, exists object2) {
			return object1 == object2;
		} else {
			return object1 exists == object2 exists;
		}
	}

	shared actual Boolean equals(Object that) {
		if (is PlayerState that) {
			return info==that.info && 
				statistic==that.statistic &&
				equalsOrBothNull(tableId, that.tableId) &&
				equalsOrBothNull(matchId, that.matchId);
		} else {
			return false;
		}
	}
	
	hash => info.hash;
}

shared PlayerState parsePlayerState(JsonObject json) => PlayerState(parsePlayerInfo(json.getObject("info")), parsePlayerStatistic(json.getObject("statistic")), parseNullableTableId(json.getObjectOrNull("tableId")), parseNullableMatchId(json.getObjectOrNull("matchId")));

shared PlayerState? parseNullablePlayerState(JsonObject? json) => if (exists json) then parsePlayerState(json) else null;

shared final class PlayerTransaction(shared String type, shared Integer amount, shared Instant timestamp) {
	shared JsonObject toJson() => JsonObject {"type" -> type, "amount" -> amount, "timestamp" -> timestamp.millisecondsOfEpoch};
}
PlayerTransaction parsePlayerTransaction(JsonObject json) {
	return PlayerTransaction(json.getString("type"), json.getInteger("amount"), Instant(json.getInteger("timestamp")));
}
