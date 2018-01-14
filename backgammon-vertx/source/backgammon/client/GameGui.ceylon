import backgammon.shared.game {
	CheckerColor,
	black,
	white,
	GameBoard,
	boardPointCount,
	whiteGraveyardPosition,
	whiteHomePosition,
	blackGraveyardPosition,
	blackHomePosition
}
import ceylon.time {
	Duration
}
import backgammon.client.browser {
	Document,
	Element
}
import ceylon.json {

	JsonObject,
	JsonArray
}

shared class GameGui(Document document) extends BaseGui(document) {
	
	shared String defaultPlayerName = "";
	shared String leaveTextKey = "_leave";
	shared String undoTextKey = "_undo";
	shared String submitTextKey = "_submit";
	shared String waitingTextKey = "_waiting";
	shared String loadingTextKey = "_loading";
	shared String readyTextKey = "_ready";
	shared String rollTextKey = "_roll";
	shared String leftTextKey = "_left";
	shared String winnerTextKey = "_winner";
	shared String tieTextKey = "_tie";
	shared String timeoutTextKey = "_timeout";
	shared String beginTexKey = "_begin";
	shared String playTextKey = "_play";
	shared String joinedTextKey = "_joined";
	
	function formatSeconds(Integer seconds) => if (seconds < 10) then "0" + seconds.string else seconds.string;
	
	shared String formatPeriod(Duration duration, String timeoutMessage) {
		if (duration.milliseconds < -999) {
			return timeoutMessage;
		}
		value totalSeconds = (duration.milliseconds + 999) / 1000;
		value minutes = totalSeconds / 60;
		value seconds = totalSeconds - minutes * 60;
		return "``minutes``:``formatSeconds(seconds)``";
	}
	
	void showDice(CheckerColor color, Integer index, String diceClass, Integer? diceValue) {
		if (exists diceValue) {
			setClass("``color``DiceNr``index+1``", diceClass, "``color``-``diceValue``");
		} else {
			addClass("``color``DiceNr``index+1``", "hidden");
		}
	}
	
	shared void showActiveDice(CheckerColor color, Integer index, Integer? diceValue) {
		showDice(color, index, "dice", diceValue);
	}
	
	shared void showFadedDice(CheckerColor color, Integer index, Integer? diceValue) {
		showDice(color, index, "dice-faded", diceValue);
	}
	
	shared void showCrossedDice(CheckerColor color, Integer index, Integer? diceValue) {
		showDice(color, index, "dice-crossed", diceValue);
	}
	
	shared void hideAllDices(CheckerColor color) {
		for (i in 0..3) {
			showActiveDice(color, i, null);
		}
	}
	
	function getDomIdUsingPoint(GameBoard board, CheckerColor color, Integer point) {
		if (point == board.graveyardPosition(color)) {
			return "point-``color``-graveyard";
		} else if (point == board.homePosition(color)) {
			return "point-``color``-home";
		} else {
			return "point-``point``";
		}
	}
	
	function parseInteger(String string) => if (is Integer result = Integer.parse(string)) then result else null;
	
	function getPointUsingDomId(String domId) {
		if (domId == "point-white-graveyard") {
			return whiteGraveyardPosition;
		} else if (domId == "point-white-home") {
			return whiteHomePosition;
		} else if (domId == "point-black-graveyard") {
			return blackGraveyardPosition;
		} else if (domId == "point-black-home") {
			return blackHomePosition;
		} else if (domId.startsWith("point-")){
			return parseInteger(String(domId.sublistFrom("point-".size)));
		} else {
			return null;
		}
	}
	
	shared void hideAllCheckers() {
		value checkers = document.getElementsByClassName("checker");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				checker.classList.add("hidden");
			}
		}
		
		value topdownCheckers = document.getElementsByClassName("topdown-checker");
		for (i in 0:topdownCheckers.length) {
			if (exists topdownChecker = topdownCheckers.item(i)) {
				topdownChecker.classList.add("hidden");
			}
		}
	}
	
	void resetCheckers(Element point, String baseCheckerClass, String checkerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				if (i < checkerCount) {
					resetClass(checker, baseCheckerClass, checkerColorClass);
				} else {
					checker.classList.add("hidden");
				}
			}
		}
	}
	
	void redrawNonEmptyPoints(GameBoard board, CheckerColor color) {
		for (position in 0:boardPointCount) {
			value domId = getDomIdUsingPoint(board, color, position);
			if (exists point = document.getElementById(domId)) {
				value count = board.countCheckers(position, color);
				if (position == board.homePosition(color)) {
					resetCheckers(point, "topdown-checker", "topdown-``color``", count);
				} else if (count > 0) {
					resetCheckers(point, "checker", "checker-``color``", count);
				}
			}
		}
	}

	shared void redrawCheckers(GameBoard board) {
		hideAllCheckers();
		redrawNonEmptyPoints(board, black);
		redrawNonEmptyPoints(board, white);
	}
	
	void addTempChecker(Element point, String checkerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		if (exists checker = checkers.item(checkerCount)) {
			resetClass(checker, "checker", checkerColorClass, "temp");
		}
	}
	
	shared Boolean isTempChecker(Element checker) {
		return checker.classList.contains("temp");
	}
	
	shared Integer? getSelectedCheckerPosition() {
		value checkers = document.getElementsByClassName("checker");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i), checker.classList.contains("selected")) {
				return getPosition(checker);
			}
		}
		return null;
	}
	
	shared void showPossibleMoves(GameBoard board, CheckerColor color, {Integer*} positions) {
		for (position in positions) {
			value domId = getDomIdUsingPoint(board, color, position);
			if (exists point = document.getElementById(domId)) {
				addTempChecker(point, "checker-``color``", board.countCheckers(position, color) + board.countCheckers(position, color.oppositeColor));
			}
		}
	}
	
	shared void hidePossibleMoves() {
		value checkers = document.getElementsByClassName("checker");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i), checker.classList.contains("temp")) {
				checker.classList.remove("temp");
				checker.classList.add("hidden");
			}
		}
	}
	
	shared void hideChecker(Element checker) {
		if (checker.classList.contains("checker")) {
			checker.classList.add("hidden");
		}
	}
	
	shared void showSelectedChecker(Element? checker) {
		deselectAllCheckers();
		if (exists checker, checker.classList.contains("checker")) {
			checker.classList.add("selected");
		}
	}
	
	function getLastChecker(GameBoard board, CheckerColor color, Integer position) {
		value domId = getDomIdUsingPoint(board, color, position);
		if (exists point = document.getElementById(domId)) {
			value count = board.countCheckers(position, color);
			value checkers = point.getElementsByTagName("div");
			return checkers.item(count - 1);
		} else {
			return null;
		}
	}
	
	shared void showSelectedPosition(GameBoard board, CheckerColor color, Integer? position) {
		if (exists position, exists checker = getLastChecker(board, color, position)) {
			showSelectedChecker(checker);
		} else {
			showSelectedChecker(null);
		}
	}
	
	void deselectAllCheckers() {
		value checkers = document.getElementsByClassName("checker");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				checker.classList.remove("selected");
			}
		}
	}
	
	shared Integer? getPosition(Element element) {
		if (element.classList.contains("point")) {
			return getPointUsingDomId(element.id);
		} else if (element.classList.contains("checker"), exists parent = element.parentElement) {
			return getPosition(parent);
		} else {
			return null;
		}
	}
	
	shared void showPlayerStatus(JsonObject statistic, JsonArray transactions) {
		dynamic {
			jQuery("#dialog-status").loadTemplate(jQuery("#dialog-status-template"), JSON.parse(statistic.string));
			jQuery("#transaction-table tbody").loadTemplate(jQuery("#transaction-row-template"), JSON.parse(transactions.string));
			jQuery("#dialog-status").dialog("open");
		}
	}
}