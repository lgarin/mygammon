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

shared final class GameGui(Document document) {
	shared String undoButtonId = "undo";
	shared String leaveButtonId = "leave";
	shared String submitButtonId = "submit";
	
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
	
	void resetClass(Element element, String* classNames) {
		value classList = element.classList;
		while (classList.length > 0) {
			if (exists item = classList.item(0)) {
				classList.remove(item);
			}
		}
		for (value className in classNames) {
			classList.add(className);
		}
	}
	
	void setClass(String elementId, String* classNames) {
		if (exists element = document.getElementById(elementId)) {
			resetClass(element, *classNames);
		}
	}
	
	void addClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.add(className);
	}
	
	void removeClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.remove(className);
	}
	
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
	
	shared void hideUndoButton() {
		addClass(undoButtonId, "hidden");
	}
	
	shared void showUndoButton(String text = undoTextKey) {
		removeClass(undoButtonId, "hidden");
		if (exists button = document.getElementById("``undoButtonId``Text")) {
			button.innerHTML = translate(text);
		}
	}

	shared void hideSubmitButton() {
		addClass(submitButtonId, "hidden");
	}
	
	shared void showSubmitButton(String text = submitTextKey) {
		removeClass(submitButtonId, "hidden");
		if (exists button = document.getElementById("``submitButtonId``Text")) {
			button.innerHTML = translate(text);
		}
	}

	shared void hideLeaveButton() {
		addClass(leaveButtonId, "hidden");
	}
	
	shared void showLeaveButton(String text = leaveTextKey) {
		removeClass(leaveButtonId, "hidden");
		if (exists button = document.getElementById("``leaveButtonId``Text")) {
			button.innerHTML = translate(text);
		}
	}

	shared void showCurrentPlayer(CheckerColor? currentColor) {
		switch (currentColor)
		case (black) {
			removeClass("whitePlayer", "selected");
			addClass("blackPlayer", "selected");
		}
		case (white) {
			addClass("whitePlayer", "selected");
			removeClass("blackPlayer", "selected");
		}
		else {
			removeClass("whitePlayer", "selected");
			removeClass("blackPlayer", "selected");
		}
	}
	
	shared void showDiceValues(CheckerColor color, Integer? value1, Integer? value2) {
		if (exists value1) {
			removeClass("``color``DiceNr1Container", "hidden");
			setClass("``color``DiceNr1", "number", "``color``-``value1``");
		} else {
			addClass("``color``DiceNr1Container", "hidden");
		}
		if (exists value2) {
			removeClass("``color``DiceNr2Container", "hidden");
			setClass("``color``DiceNr2", "number", "``color``-``value2``");
		} else {
			addClass("``color``DiceNr2Container", "hidden");
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
	
	void hideAllCheckers() {
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
	
	shared void showPlayerInfo(CheckerColor color, String? name, String? pictureUrl) {
		if (exists playerLabel = document.getElementById("``color``PlayerName")) {
			playerLabel.innerHTML = name else defaultPlayerName;
		}
		if (exists playerImage = document.getElementById("``color``PlayerImage")) {
			if (exists pictureUrl) {
				playerImage.setAttribute("src", pictureUrl);
				playerImage.classList.remove("player-unknown");
			} else {
				playerImage.setAttribute("src", "");
				playerImage.classList.add("player-unknown");
			}
		}
	}
	
	shared void showPlayerMessage(CheckerColor color, String message, Boolean busy) {
		if (exists playerTimer = document.getElementById("``color``PlayerTimer")) {
			playerTimer.innerHTML = translate(message);
		}
		if (exists playerActivity = document.getElementById("``color``PlayerActivity")) {
			if (busy) {
				playerActivity.classList.add("player-busy");
				playerActivity.classList.remove("player-ready");
			} else {
				playerActivity.classList.remove("player-busy");
				playerActivity.classList.add("player-ready");
			}
		}
	}
	
	void resetState(CheckerColor color, String playerMessage) {
		showDiceValues(color, null, null);
		showPlayerInfo(color, null, null);
		showPlayerMessage(color, playerMessage, true);
	}
	
	shared void showInitialState(String playerMessage = waitingTextKey) {
		showCurrentPlayer(null);
		hideAllCheckers();
		resetState(black, playerMessage);
		resetState(white, playerMessage);
		hideLeaveButton();
		hideUndoButton();
		hideSubmitButton();
	}
	
	shared void showEmptyGame() {
		showCurrentPlayer(null);
		showDiceValues(black, null, null);
		showDiceValues(white, null, null);
		hideAllCheckers();
	}
	
	shared void showDialog(String dialogName) {
		dynamic {
			jQuery("#``dialogName``").dialog("open");
		}
	}
	
	shared String translate(String key) {
		if (key.empty || !key.startsWith("_")) {
			return key;
		}
		dynamic {
			return jQuery("#i18n #``key``").text();
		}
	}
}