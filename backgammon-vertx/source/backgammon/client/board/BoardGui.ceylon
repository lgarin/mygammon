import backgammon.client {
	GameGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {
	PlayerState
}
import backgammon.shared.game {
	black,
	CheckerColor,
	white
}
shared class BoardGui(Document document) extends GameGui(document) {
	
	shared String hiddenClass = "hidden";
	shared String undoButtonId = "undo";
	shared String leaveButtonId = "leave";
	shared String joinButtonId = "join";
	shared String submitButtonId = "submit";
	shared String exitButtonId = "exit";
	shared String homeButtonId = "home";
	shared String startButtonId = "start";
	shared String statusTextId = "status";
	shared String statusUserId = "currentUser";
	shared String statusBalanceId = "currentBalance";
	shared String matchPotId = "matchPot";
	shared String matchPotAmountId = "matchPotAmount";
	
	shared void hideUndoButton() {
		addClass(undoButtonId, hiddenClass);
	}
	
	shared void showUndoButton(String text = undoTextKey) {
		removeClass(undoButtonId, hiddenClass);
		if (exists button = document.getElementById("``undoButtonId``Text")) {
			button.innerHTML = translate(text);
		}
	}
	
	shared void hideSubmitButton() {
		addClass(submitButtonId, hiddenClass);
	}
	
	shared void showSubmitButton(String text = submitTextKey) {
		removeClass(submitButtonId, hiddenClass);
		if (exists button = document.getElementById("``submitButtonId``Text")) {
			button.innerHTML = translate(text);
		}
	}
	
	shared void hideLeaveButton() {
		addClass(leaveButtonId, hiddenClass);
	}
	
	shared void showLeaveButton() {
		removeClass(leaveButtonId, hiddenClass);
	}

	shared void showJoinButton() {
		removeClass(joinButtonId, hiddenClass);
	}

	shared void hideJoinButton() {
		addClass(joinButtonId, hiddenClass);
	}
	
	shared void hideExitButton() {
		addClass(exitButtonId, hiddenClass);
	}
	
	shared void showExitButton() {
		removeClass(exitButtonId, hiddenClass);
	}
	
	shared void hideHomeButton() {
		addClass(homeButtonId, hiddenClass);
	}
	
	shared void showHomeButton() {
		removeClass(homeButtonId, hiddenClass);
	}
	
	shared void hideStartButton() {
		addClass(startButtonId, hiddenClass);
	}
	
	shared void showStartButton() {
		removeClass(startButtonId, hiddenClass);
	}
	
	shared void showStatusText(String user, Integer balance) {
		if (exists statusUserText = document.getElementById(statusUserId)) {
			statusUserText.innerHTML = user;
		}
		if (exists statusBalanceText = document.getElementById(statusBalanceId)) {
			statusBalanceText.innerHTML = balance.string;
		}
		removeClass(statusTextId, hiddenClass);
	}
	
	shared void hideStatusText() {
		addClass(statusTextId, hiddenClass);
	}
	
	shared void showMatchPot(Integer matchPot) {
		removeClass(matchPotId, hiddenClass);
		if (exists matchPotAmountText = document.getElementById(matchPotAmountId)) {
			matchPotAmountText.innerHTML = matchPot.string;
		}
	}
	
	shared void hideMatchPot() {
		addClass(matchPotId, hiddenClass);
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
	
	shared void showPlayerInfo(CheckerColor color, String? name, Integer? level) {
		if (exists playerLabel = document.getElementById("``color``PlayerName")) {
			playerLabel.innerHTML = name else defaultPlayerName;
		}
		if (exists playerLevel = level) {
			setClass("``color``PlayerLevel", "player-level", "level-``playerLevel``");
		} else {
			setClass("``color``PlayerLevel", hiddenClass);
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
		hideAllDices(color);
		showPlayerInfo(color, null, null);
		showPlayerMessage(color, playerMessage, true);
	}
	
	shared void showInitialGame(String playerMessage = waitingTextKey) {
		showCurrentPlayer(null);
		hideAllCheckers();
		resetState(black, playerMessage);
		resetState(white, playerMessage);
		hideUndoButton();
		hideSubmitButton();
	}
	
	shared void showEmptyGame() {
		showCurrentPlayer(null);
		hideAllDices(black);
		hideAllDices(white);
		hideAllCheckers();
	}
	
	shared default void showBeginState(PlayerState playerState) {
		showExitButton();
		showStatusText(playerState.info.name, playerState.statistic.balance);
		hideStartButton();
		showEmptyGame();
	}
}