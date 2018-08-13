import backgammon.client.browser {
	Document,
	HTMLElement,
	Element
}
import backgammon.shared {
	PlayerState,
	PlayerInfo
}
import backgammon.shared.game {
	black,
	CheckerColor,
	white,
	DiceRoll
}
import ceylon.json {

	JsonArray,
	JsonObject
}
shared class TableGui(Document document) extends GameGui(document) {
	
	shared String undoButtonId = "undo";
	shared String submitButtonId = "submit";
	shared String jokerButtonId = "joker";
	shared String chatButtonId = "chat";
	shared String chatPostButtonId = "chat-post";
	shared String chatInputFieldId = "chat-input";
	shared String exitButtonId = "exit";
	shared String statusUserId = "currentUser";
	shared String statusBalanceId = "currentBalance";
	shared String matchPotId = "matchPot";
	shared String matchPotAmountId = "matchPotAmount";
	shared String accountButtonId = "account";
	shared String jokerDiceNr1Id = "jokerDiceNr1";
	shared String jokerDiceNr2Id = "jokerDiceNr2";
	shared String jokerTakeTurnId = "joker-take-turn";
	shared String jokerControlRollId = "joker-control-roll";
	
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

	shared void hideJokerButton() {
		addClass(jokerButtonId, hiddenClass);
		hideDialog("dialog-joker");
	}
	
	shared void showJokerButton() {
		removeClass(jokerButtonId, hiddenClass);
	}
	
	shared void showJokerDialog(CheckerColor color) {
		setClass(jokerDiceNr1Id, "btn", "dice-choice", "``color.oppositeColor``-1");
		setClass(jokerDiceNr2Id, "btn", "dice-choice", "``color.oppositeColor``-2");
		showDialog("dialog-joker");
	}
	
	function findDiceValue(Element target, CheckerColor color) {
		for (value i in 1..6) {
			if (target.classList.contains("``color``-``i``")) {
				return i;
			}
		}
		return null;
	}
	
	shared void switchJokerDice(HTMLElement target, CheckerColor color) {
		if (exists current = findDiceValue(target, color.oppositeColor)) {
			target.classList.remove("``color.oppositeColor``-``current``");
			target.classList.add("``color.oppositeColor``-``(current % 6) + 1``");
		}
	}
	
	shared DiceRoll? readJokerRoll(CheckerColor color) {
		if (exists diceNr1 = document.getElementById(jokerDiceNr1Id), exists diceNr2 = document.getElementById(jokerDiceNr2Id)) {
			if (exists value1 = findDiceValue(diceNr1, color.oppositeColor), exists value2 = findDiceValue(diceNr2, color.oppositeColor)) {
				return DiceRoll(value1, value2);
			}
		}
		return null;
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
		hideJokerButton();
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
	
	
	class TemplateParameters(shared Boolean append) {}
	
	shared void showChatMessages(JsonArray data) {
		dynamic {
			if (data.empty) {
				jQuery("#chat-content ul").loadTemplate(jQuery("#chat-empty-template"));
			} else {
				dynamic chatContent = jQuery("#chat-content ul"); 
				chatContent.loadTemplate(jQuery("#chat-message-template"), JSON.parse(data.string));
				jQuery("time.timeago").timeago();
				chatContent.scrollTop(chatContent.get(0).scrollHeight);
			}
		}
	}
	
	shared void appendChatMessage(JsonObject data) {
		dynamic {
			dynamic chatContent = jQuery("#chat-content ul");
			chatContent.loadTemplate(jQuery("#chat-message-template"), JSON.parse(data.string), TemplateParameters(true));
			jQuery("time.timeago").timeago();
			dynamic domElement = chatContent.get(0); 
			if (domElement.scrollHeight - domElement.scrollTop - domElement.clientHeight <= 100) {
				chatContent.scrollTop(domElement.scrollHeight);
			}
		}
	}
	shared void showChatIcon(Integer newMessageCount) {
		if (exists badge = document.getElementById("newChat")) {
			badge.innerHTML = newMessageCount.string;
		}
		if (newMessageCount > 0) {
			removeClass("newChat", hiddenClass);
		} else {
			addClass("newChat", hiddenClass);
		}
		removeClass("chat", hiddenClass);
	}
}