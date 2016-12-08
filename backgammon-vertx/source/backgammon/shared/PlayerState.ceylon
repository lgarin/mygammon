import ceylon.json {
	JsonObject=Object
}

shared final class PlayerStatistic(shared Integer playedGames = 0, shared Integer wonGames = 0, shared Integer score = 0) {
	shared Integer winPercentage => if (playedGames > 0) then 100 * wonGames / playedGames else 0;
	shared JsonObject toJson() => JsonObject {"playedGames" -> playedGames, "wonGames" -> wonGames, "score" -> score};
	shared PlayerStatistic increaseGameCount() => PlayerStatistic(playedGames + 1, wonGames, score);
	shared PlayerStatistic increaseWinCount(Integer winScore) => PlayerStatistic(playedGames, wonGames + 1, score + winScore);
}

shared PlayerStatistic parsePlayerStatistic(JsonObject json) => PlayerStatistic(json.getInteger("playedGames"), json.getInteger("wonGames"), json.getInteger("score"));

shared final class PlayerState(shared String id, shared String name, shared PlayerStatistic statistic, shared TableId? tableId, shared MatchId? matchId, shared String? pictureUrl = null, shared String? iconUrl = null) {
	shared JsonObject toJson() => JsonObject {"id" -> id, "name" -> name, "statistic" -> statistic.toJson(), "tableId" -> tableId?.toJson(), "matchId" -> matchId?.toJson(), "pictureUrl" -> pictureUrl, "iconUrl" -> iconUrl};
	shared PlayerId playerId => PlayerId(id);
	shared PlayerInfo toPlayerInfo() => PlayerInfo(id, name, pictureUrl, iconUrl);
	shared Boolean isAtTable(TableId otherTableId) => if (exists tableId) then tableId == otherTableId else false;
	shared PlayerState withTable(TableId? tableId) => PlayerState(id, name, statistic, tableId, matchId, pictureUrl, iconUrl);
}

shared PlayerState parsePlayerState(JsonObject json) => PlayerState(json.getString("id"), json.getString("name"), parsePlayerStatistic(json.getObject("statistic")), parseNullableTableId(json.getObjectOrNull("tableId")), parseNullableMatchId(json.getObjectOrNull("matchId")), json.getStringOrNull("pictureUrl"), json.getStringOrNull("iconUrl"));

shared PlayerState? parseNullablePlayerState(JsonObject? json) => if (exists json) then parsePlayerState(json) else null;
