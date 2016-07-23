import backgammon.game {
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
import backgammon.browser {

	Document,
	Element
}

shared final class GameGui(Document document) {
	shared String undoButtonId = "undo";
	shared String leaveButtonId = "leave";
	shared String submitButtonId = "submit";
	
	value defaultPlayerName = "";
	value initalPlayerMessage = "Waiting...";
	
	void setClass(String elementId, String* classNames) {
		if (exists classList = document.getElementById(elementId)?.classList) {
			for (i in 0:classList.length) {
				if (exists item = classList.item(i)) {
					classList.remove(item);
				}
			}
			for (value className in classNames) {
				classList.add(className);
			}
		}
	}
	
	void addClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.add(className);
	}
	
	void removeClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.remove(className);
	}
	
	function formatSeconds(Integer seconds) => if (seconds < 10) then "0" + seconds.string else seconds.string;
	
	shared String formatPeriod(Duration duration) {
		value totalSeconds = (duration.milliseconds + 999) / 1000;
		value minutes = totalSeconds / 60;
		value seconds = totalSeconds - minutes * 60;
		return "``minutes``:``formatSeconds(seconds)``";
	}
	
	shared void hideUndoButton() {
		addClass(undoButtonId, "hidden");
	}
	
	shared void showUndoButton(String? text) {
		removeClass(undoButtonId, "hidden");
		if (exists button = document.getElementById("``undoButtonId``Text")) {
			button.innerHTML = text else "Undo";
			button.classList.remove("hidden");
		}
	}

	shared void hideSubmitButton() {
		addClass(submitButtonId, "hidden");
	}
	
	shared void showSubmitButton(String? text) {
		removeClass(submitButtonId, "hidden");
		if (exists button = document.getElementById("``submitButtonId``Text")) {
			button.innerHTML = text else "Submit";
		}
	}

	shared void hideLeaveButton() {
		addClass(leaveButtonId, "hidden");
	}
	
	shared void showLeaveButton(String? text) {
		removeClass(leaveButtonId, "hidden");
		if (exists button = document.getElementById("``leaveButtonId``Text")) {
			button.innerHTML = text else "Leave";
			button.classList.remove("hidden");
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
			removeClass("``color.name``DiceNr1Container", "hidden");
			setClass("``color.name``DiceNr1", "number", "``color.name``-``value1``");
		} else {
			addClass("``color.name``DiceNr1Container", "hidden");
		}
		if (exists value2) {
			removeClass("``color.name``DiceNr2Container", "hidden");
			setClass("``color.name``DiceNr2", "number", "``color.name``-``value2``");
		} else {
			addClass("``color.name``DiceNr2Container", "hidden");
		}
	}
	
	function getDomIdUsingPoint(GameBoard board, CheckerColor color, Integer point) {
		if (point == board.graveyardPosition(color)) {
			return "point-``color.name``-graveyard";
		} else if (point == board.homePosition(color)) {
			return "point-``color.name``-home";
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
	
	void resetCheckers(Element point, String checkerColorClass, String oppositeCheckerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				if (i < checkerCount) {
					checker.classList.remove("temp");
					checker.classList.remove("selected");
					checker.classList.remove(oppositeCheckerColorClass);
					checker.classList.add(checkerColorClass);
					checker.classList.remove("hidden");
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
					resetCheckers(point, "topdown-``color.name``", "topdown-``color.oppositeColor.name``", count);
				} else if (count > 0) {
					resetCheckers(point, "checker-``color.name``", "checker-``color.oppositeColor.name``", count);
				}
			}
		}
	}

	shared void redrawCheckers(GameBoard board) {
		hideAllCheckers();
		redrawNonEmptyPoints(board, black);
		redrawNonEmptyPoints(board, white);
	}
	
	void addTempChecker(Element point, String checkerColorClass, String oppositeCheckerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		if (exists checker = checkers.item(checkerCount + 1)) {
			checker.classList.remove(oppositeCheckerColorClass);
			checker.classList.add(checkerColorClass);
			checker.classList.add("temp");
			checker.classList.remove("hidden");
		}
	}
	
	shared void showPossibleMoves(GameBoard board, CheckerColor color, {Integer*} positions) {
		for (position in positions) {
			value domId = getDomIdUsingPoint(board, color, position);
			if (exists point = document.getElementById(domId)) {
				addTempChecker(point, "checker-``color.name``", "checker-``color.oppositeColor.name``", board.countCheckers(position, color));
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
	
	shared void showSelectedChecker(Element checker) {
		checker.classList.add("selected");
	}
	
	shared void deselectAllCheckers() {
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
		if (exists playerLabel = document.getElementById("``color.name``PlayerName")) {
			playerLabel.innerHTML = name else defaultPlayerName;
		}
		if (exists playerImage = document.getElementById("``color.name``PlayerImage")) {
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
		if (exists playerTimer = document.getElementById("``color.name``PlayerTimer")) {
			playerTimer.innerHTML = message;
		}
		if (exists playerActivity = document.getElementById("``color.name``PlayerActivity")) {
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
		hideLeaveButton();
		hideUndoButton();
		hideSubmitButton();
	}
	
	shared void showInitialState(String playerMessage = initalPlayerMessage) {
		showCurrentPlayer(null);
		hideAllCheckers();
		resetState(black, playerMessage);
		resetState(white, playerMessage);
	}
	
	shared void showEmptyGame() {
		showCurrentPlayer(null);
		showDiceValues(black, null, null);
		showDiceValues(white, null, null);
		hideAllCheckers();
	}
}