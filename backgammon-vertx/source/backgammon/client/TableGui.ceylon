import backgammon.client.browser {
	Document
}
import backgammon.shared {
	PlayerState,
	PlayerInfo
}
import backgammon.shared.game {
	black,
	CheckerColor,
	white
}
shared class TableGui(Document document) extends GameGui(document) {
	
	shared String undoButtonId = "undo";
	shared String submitButtonId = "submit";
	shared String jockerButtonId = "jocker";
	shared String exitButtonId = "exit";
	shared String statusUserId = "currentUser";
	shared String statusBalanceId = "currentBalance";
	shared String matchPotId = "matchPot";
	shared String matchPotAmountId = "matchPotAmount";
	shared String accountButtonId = "account";
	
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

	shared void hideExitButton() {
		addClass(exitButtonId, hiddenClass);
	}
	
	shared void showExitButton() {
		removeClass(exitButtonId, hiddenClass);
	}

	shared void hideJockerButton() {
		addClass(jockerButtonId, hiddenClass);
	}
	
	shared void showJockerButton() {
		removeClass(jockerButtonId, hiddenClass);
	}
	
	shared void showAccountStatus(String user, Integer balance) {
		if (exists statusUserText = document.getElementById(statusUserId)) {
			statusUserText.innerHTML = user;
		}
		if (exists statusBalanceText = document.getElementById(statusBalanceId)) {
			statusBalanceText.innerHTML = balance.string;
		}
		removeClass(accountButtonId, hiddenClass);
	}
	
	shared void hideAccountStatus() {
		addClass(accountButtonId, hiddenClass);
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
	
	shared void showPlayerInfo(CheckerColor color, String? roomId, PlayerInfo? playerInfo) {
		if (exists playerLink = document.getElementById("``color``PlayerName")) {
			if (exists playerInfo, exists roomId) {
				playerLink.setAttribute("href", "/room/``roomId``/player?id=``playerInfo.id``");
				playerLink.innerHTML = playerInfo.name;
				removeClass("``color``PlayerName", hiddenClass);
			} else {
				playerLink.setAttribute("href", "#");
				playerLink.innerHTML = defaultPlayerName;
				addClass("``color``PlayerName", hiddenClass);
			}
		}
		if (exists playerLevel = playerInfo?.level) {
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
		hideJockerButton();
	}
	
	shared void showEmptyGame() {
		showCurrentPlayer(null);
		hideAllDices(black);
		hideAllDices(white);
		hideAllCheckers();
	}
	
	shared default void showBeginState(PlayerState playerState) {
		showExitButton();
		showAccountStatus(playerState.info.name, playerState.statistic.balance);
		showEmptyGame();
	}
}