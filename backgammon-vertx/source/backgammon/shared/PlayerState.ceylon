import ceylon.json {
	JsonObject=Object
}

shared final class PlayerStatistic(shared Integer balance, shared Integer playedGames = 0, shared Integer wonGames = 0, shared Integer score = 0) extends Object() {
	shared Integer winPercentage => if (playedGames > 0) then 100 * wonGames / playedGames else 0;
	shared JsonObject toJson() => JsonObject {"balance" -> balance, "playedGames" -> playedGames, "wonGames" -> wonGames, "score" -> score};
	shared PlayerStatistic increaseGameCount() => PlayerStatistic(balance, playedGames + 1, wonGames, score);
	shared PlayerStatistic increaseWinCount(Integer winScore) => PlayerStatistic(balance, playedGames, wonGames + 1, score + winScore);
	shared PlayerStatistic placeBet(Integer bet) => PlayerStatistic(balance - bet, playedGames, wonGames, score);
	
	string => toJson().string;
	shared actual Boolean equals(Object that) {
		if (is PlayerStatistic that) {
			return balance==that.balance && 
				playedGames==that.playedGames && 
				wonGames==that.wonGames && 
				score==that.score;
		}
		else {
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
}

shared PlayerStatistic parsePlayerStatistic(JsonObject json) => PlayerStatistic(json.getInteger("balance"), json.getInteger("playedGames"), json.getInteger("wonGames"), json.getInteger("score"));

shared final class PlayerState(shared String id, shared String name, shared PlayerStatistic statistic, shared TableId? tableId, shared MatchId? matchId, shared String? pictureUrl = null, shared String? iconUrl = null) extends Object() {
	shared JsonObject toJson() => JsonObject {"id" -> id, "name" -> name, "statistic" -> statistic.toJson(), "tableId" -> tableId?.toJson(), "matchId" -> matchId?.toJson(), "pictureUrl" -> pictureUrl, "iconUrl" -> iconUrl};
	shared PlayerId playerId => PlayerId(id);
	shared PlayerInfo toPlayerInfo() => PlayerInfo(id, name, statistic.balance, pictureUrl, iconUrl);
	shared Boolean isAtTable(TableId otherTableId) => if (exists tableId) then tableId == otherTableId else false;
	shared Boolean isPlayingAtTable(TableId otherTableId) => matchId exists && isAtTable(otherTableId);
	shared PlayerState withTable(TableId? tableId) => PlayerState(id, name, statistic, tableId, matchId, pictureUrl, iconUrl);
	
	string => toJson().string;
	
	shared actual Boolean equals(Object that) {
		if (is PlayerState that) {
			return id==that.id && 
				name==that.name && 
				statistic==that.statistic;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + id.hash;
		hash = 31*hash + name.hash;
		hash = 31*hash + statistic.hash;
		return hash;
	}
}

shared PlayerState parsePlayerState(JsonObject json) => PlayerState(json.getString("id"), json.getString("name"), parsePlayerStatistic(json.getObject("statistic")), parseNullableTableId(json.getObjectOrNull("tableId")), parseNullableMatchId(json.getObjectOrNull("matchId")), json.getStringOrNull("pictureUrl"), json.getStringOrNull("iconUrl"));

shared PlayerState? parseNullablePlayerState(JsonObject? json) => if (exists json) then parsePlayerState(json) else null;
