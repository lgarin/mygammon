import backgammon.shared.game {

	black,
	CheckerColor,
	white
}
import backgammon.client.browser {

	Document
}
import backgammon.client {
	GameGui
}
import backgammon.shared {

	PlayerInfo
}
shared class BoardGui(Document document) extends GameGui(document) {
	
	shared String undoButtonId = "undo";
	shared String leaveButtonId = "leave";
	shared String submitButtonId = "submit";
	shared String exitButtonId = "exit";
	shared String homeButtonId = "home";
	shared String startButtonId = "start";
	
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
	
	shared void hideExitButton() {
		addClass(exitButtonId, "hidden");
	}
	
	shared void showExitButton() {
		removeClass(exitButtonId, "hidden");
	}
	
	shared void hideHomeButton() {
		addClass(homeButtonId, "hidden");
	}
	
	shared void showHomeButton() {
		removeClass(homeButtonId, "hidden");
	}
	
	shared void hideStartButton() {
		addClass(startButtonId, "hidden");
	}
	
	shared void showStartButton() {
		removeClass(startButtonId, "hidden");
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
		hideAllDices(color);
		showPlayerInfo(color, null, null);
		showPlayerMessage(color, playerMessage, true);
	}
	
	shared void showInitialGame(String playerMessage = waitingTextKey) {
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
		hideAllDices(black);
		hideAllDices(white);
		hideAllCheckers();
	}
	
	shared default void showBeginState(PlayerInfo playerInfo) {
		showExitButton();
		hideStartButton();
		showEmptyGame();
	}
}