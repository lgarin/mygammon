import backgammon.game {

	CheckerColor,
	black,
	white,
	GameBoard,
	GameMove
}
import ceylon.interop.browser.dom { 
	Document,
	Event,
	EventListener,
	Element,
	HTMLElement }


shared final class GameGui(Document document) {
	
	value board = GameBoard();
	
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
	
	shared void disableUndoButton() {
		addClass("undo", "hidden");
	}

	shared void disableSubmitButton() {
		addClass("submit", "hidden");
	}

	shared void disableLeaveButton() {
		addClass("leave", "hidden");
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
	
	function getDomIdUsingPoint(CheckerColor color, Integer point) {
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
			return board.whiteGraveyardPosition;
		} else if (domId == "point-white-home") {
			return board.whiteHomePosition;
		} else if (domId == "point-black-graveyard") {
			return board.blackGraveyardPosition;
		} else if (domId == "point-black-home") {
			return board.blackHomePosition;
		} else if (domId.startsWith("point-")){
			return parseInteger(String(domId.sublistFrom("point-".size)));
		} else {
			return null;
		}
	}
	
	void resetCheckers(Element point, String checkerColorClass, String oppositeCheckerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				if (i < checkerCount) {
					checker.classList.remove("hidden");
					checker.classList.remove("temp");
					checker.classList.add(checkerColorClass);
				} else {
					checker.classList.add("hidden");
					checker.classList.remove("temp");
					checker.classList.remove(oppositeCheckerColorClass);
					checker.classList.remove(checkerColorClass);
				}
			}
		}
	}
	
	shared void redrawCheckers(CheckerColor color, [Integer*] counts) {
		board.setCheckerCounts(color, counts);
		for (position in 0:counts.size) {
			value domId = getDomIdUsingPoint(color, position);
			if (exists point = document.getElementById(domId)) {
				if (position == board.homePosition(color)) {
					resetCheckers(point, "topdown-``color.name``", "topdown-``color.oppositeColor.name``", counts[position] else 0);
				} else {
					resetCheckers(point, "checker-``color.name``", "checker-``color.oppositeColor.name``", counts[position] else 0);
				}
			}
		}
	}
	
	void addTempChecker(Element point, String checkerColorClass, String oppositeCheckerColorClass, Integer checkerCount) {
		value checkers = point.getElementsByTagName("div");
		if (exists checker = checkers.item(checkerCount + 1)) {
			checker.classList.remove("hidden");
			checker.classList.remove(oppositeCheckerColorClass);
			checker.classList.add(checkerColorClass);
			checker.classList.add("temp");
		}
	}
	
	shared void showPossibleMoves(CheckerColor color, {Integer*} positions) {
		for (position in positions) {
			value domId = getDomIdUsingPoint(color, position);
			if (exists point = document.getElementById(domId)) {
				addTempChecker(point, "checker-``color.name``", "checker-``color.oppositeColor.name``", board.countCheckers(position, color));
			}
		}
	}

	shared void onDrag(Boolean dragHandler(Integer position)) {
		value checkers = document.getElementsByClassName("pointer");
		for (i in 0:checkers.length) {
			if (exists checker = checkers.item(i)) {
				
			}
		}
	}
}