import backgammon.shared {

	PlayerStatistic,
	PlayerTransaction,
	PlayerInfo
}
import ceylon.json {

	JsonObject,
	JsonArray
}
import ceylon.time {

	DateTime
}
final shared class PlayerStatusModel(PlayerInfo info, PlayerStatistic statistic, [PlayerTransaction*] transactions) {

	shared JsonObject buildStatisticData() {
		value levelClass = if (exists level = info.level) then "player-level level-``level``" else "hidden";
		return JsonObject {"id" -> info.id, "name" -> info.name, "levelClass" -> levelClass, "score" -> statistic.score, "win" -> statistic.winPercentage, "lost" -> statistic.lostPercentage, "games" -> statistic.playedGames, "balance" -> statistic.balance};
	}

	function formatTwoDigitInteger(Integer integer) => integer < 10 then "0" + integer.string else integer.string;

	function formatTimestamp(DateTime dateTime) {
		return "``formatTwoDigitInteger(dateTime.day)``.``formatTwoDigitInteger(dateTime.month.integer)``.``dateTime.year`` ``formatTwoDigitInteger(dateTime.hours)``:``formatTwoDigitInteger(dateTime.minutes)``:``formatTwoDigitInteger(dateTime.seconds)``";
	}
	
	shared JsonArray buildTransactionList() {
		
		return JsonArray {for (t in transactions) JsonObject { "type" -> t.type, "amount" -> t.amount, "dateTime" -> formatTimestamp(t.timestamp.dateTime()), "timestamp" -> t.timestamp.millisecondsOfEpoch }};
	}
}