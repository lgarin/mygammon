import backgammon.client.board {
	BoardGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {
	PlayerState,
	PlayerInfo,
	PlayerStatistic,
	PlayerTransaction
}

import ceylon.json {
	JsonObject,
	JsonArray
}
import ceylon.time {
	DateTime
}
shared class AccountGui(Document document) extends BoardGui(document) {
	
	shared String playButtonId = "play";
	
	value tablePreviewId = "table-preview";
	
	shared void hidePlayButton() {
		addClass(playButtonId, hiddenClass);
	}
	
	shared void showPlayButton() {
		removeClass(playButtonId, hiddenClass);
	}

	shared void hideTablePreview() {
		addClass(tablePreviewId, hiddenClass);
	}
	
	shared void showTablePreview() {
		removeClass(tablePreviewId, hiddenClass);
	}
	
	function buildAccountData(PlayerInfo info, PlayerStatistic statistic) {
		value levelClass = if (exists level = info.level) then "player-level level-``level``" else "hidden";
		return JsonObject {"id" -> info.id, "name" -> info.name, "levelClass" -> levelClass, "score" -> statistic.score, "win" -> statistic.winPercentage, "lost" -> statistic.lostPercentage, "games" -> statistic.playedGames, "balance" -> statistic.balance};
	}
	
	function formatTwoDigitInteger(Integer integer) => integer < 10 then "0" + integer.string else integer.string;
	
	function formatTimestamp(DateTime dateTime) {
		return "``formatTwoDigitInteger(dateTime.day)``.``formatTwoDigitInteger(dateTime.month.integer)``.``dateTime.year`` ``formatTwoDigitInteger(dateTime.hours)``:``formatTwoDigitInteger(dateTime.minutes)``:``formatTwoDigitInteger(dateTime.seconds)``";
	}
	
	function buildTransactionArray([PlayerTransaction*] transactions) {
		
		return JsonArray {for (t in transactions) JsonObject { "type" -> t.type, "amount" -> t.amount, "dateTime" -> formatTimestamp(t.timestamp.dateTime()), "timestamp" -> t.timestamp.millisecondsOfEpoch }};
	}

	shared actual void showBeginState(PlayerState playerState) {
		super.showBeginState(playerState);
		showPlayButton();
		hideTablePreview();
		showAccountData(playerState.info, playerState.statistic);
	}
	
	shared void showAccountData(PlayerInfo info, PlayerStatistic statistic) {
		value accountData = buildAccountData(info, statistic); 
		dynamic {
			jQuery("#account-info").loadTemplate(jQuery("#account-info-template"), JSON.parse(accountData.string));
		}
		removeClass("account-info", hiddenClass);
	}
	
	shared void showTransactions([PlayerTransaction*] transactions) {
		value transactionArray = buildTransactionArray(transactions);
		dynamic {
			jQuery("#transaction-table tbody").loadTemplate(jQuery("#transaction-row-template"), JSON.parse(transactionArray.string));
			jQuery("#transaction-table").dataTable();
		}
		removeClass("transaction-table", hiddenClass);
	}
}