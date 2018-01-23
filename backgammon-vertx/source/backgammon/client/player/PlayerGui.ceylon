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
	GameStatisticMessage,
	PlayerId,
	RoomId
}

import ceylon.json {
	JsonObject,
	JsonArray
}
import ceylon.time {
	Instant,
	Duration
}
shared class PlayerGui(Document document) extends BoardGui(document) {
	
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
	
	function formatTimestamp(Instant timestamp) {
		value dateTime = timestamp.dateTime();
		return "``formatTwoDigitInteger(dateTime.day)``.``formatTwoDigitInteger(dateTime.month.integer)``.``dateTime.year`` ``formatTwoDigitInteger(dateTime.hours)``:``formatTwoDigitInteger(dateTime.minutes)``:``formatTwoDigitInteger(dateTime.seconds)``";
	}
	
	function formatDuration(Duration duration) {
		value period = duration.period.normalized();
		return "``formatTwoDigitInteger(period.hours)``:``formatTwoDigitInteger(period.minutes)``:``formatTwoDigitInteger(period.seconds)``";
	}
	
	function formatInteger(Integer integer) {
		return "``integer < 0 then "-" else "+"````integer``";
	}
	
	function buildGameData(RoomId roomId, PlayerId playerId, GameStatisticMessage game) {
		if (exists opponent = game.opponent(playerId), exists color = game.color(playerId)) {
			return JsonObject { "opponent" -> opponent.name, "opponent-link" -> "/room/``roomId``/player?id=``opponent.id``", "score" -> formatInteger(game.statistic.score(color)), "diceDetla" -> formatInteger(game.statistic.diceDelta(color)), "duration" -> formatDuration(game.statistic.duration), "dateTime" -> formatTimestamp(game.statistic.startTime), "timestamp" -> game.statistic.startTime.millisecondsOfEpoch };
		} else {
			return JsonObject {  } ;
		}
	}
	
	function buildGameArray(RoomId roomId, PlayerId playerId, [GameStatisticMessage*] games) {
		return JsonArray {for (g in games) buildGameData(roomId, playerId, g)};
	}

	shared actual void showBeginState(PlayerState playerState) {
		super.showBeginState(playerState);
		showPlayButton();
		hideTablePreview();
	}
	
	shared void showPlayer(PlayerInfo info, PlayerStatistic statistic) {
		value accountData = buildAccountData(info, statistic); 
		dynamic {
			jQuery("#player-info").loadTemplate(jQuery("#player-info-template"), JSON.parse(accountData.string));
		}
		removeClass("player-info", hiddenClass);
	}
	
	shared void showGames(RoomId roomId, PlayerId playerId, [GameStatisticMessage*] games) {
		value gameArray = buildGameArray(roomId, playerId, games);
		dynamic {
			jQuery("#game-table tbody").loadTemplate(jQuery("#game-row-template"), JSON.parse(gameArray.string));
			jQuery("#game-table").dataTable();
		}
		removeClass("game-table", hiddenClass);
	}
}