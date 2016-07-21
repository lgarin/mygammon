import backgammon.common {
	MatchState,
	PlayerInfo,
	InboundGameMessage,
	GameStateRequestMessage,
	PlayerId,
	OutboundMatchMessage,
	JoiningMatchMessage,
	StartMatchMessage,
	LeaftMatchMessage
}
import backgammon.game {
	player2Color,
	player1Color,
	CheckerColor
}
shared final class MatchClient(PlayerInfo player, MatchState match, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	value playerId = PlayerId(player.id);
	variable GameClient? gameClient = null;
	
	void showWin(CheckerColor? color) {
		if (exists currentColor = color) {
			gui.showPlayerMessage(currentColor, "Winner", false);
			gui.showPlayerMessage(currentColor.oppositeColor, "", false);
		} else {
			gui.showPlayerMessage(player1Color, "Tie", false);
			gui.showPlayerMessage(player2Color, "Tie", false);
		}
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	void showMatchBegin(MatchState match) {
		gui.showPlayerMessage(player1Color, match.playerReady(player1Color) then "Ready" else "Play?", false);
		gui.showPlayerMessage(player2Color, match.playerReady(player2Color) then "Ready" else "Play?", false);
		if (match.mustStartMatch(playerId)) {
			gui.showSubmitButton("Play");
		} else {
			gui.hideSubmitButton();
		}
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	void showResumingGame() {
		gui.showPlayerMessage(player1Color, "Loading...", true);
		gui.showPlayerMessage(player2Color, "Loading...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);	}
	
	shared void showState() {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
		gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
		if (match.gameStarted) {
			showResumingGame();
			gameClient = GameClient(playerId, match.id, gui, messageBroadcaster);
			messageBroadcaster(GameStateRequestMessage(match.id, playerId));
		} else if (match.gameEnded) {
			showWin(match.winnerColor);
		} else {
			showMatchBegin(match);
		}
	}
	
	shared Boolean handleTableMessage(OutboundMatchMessage message) {
		if (message.matchId != match.id) {
			return false;
		}
		
		switch (message)
		case (is JoiningMatchMessage) {
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Joined", false);
			}
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.showLeaveButton(null);
			return true;
		}
		case (is StartMatchMessage) {
			gameClient = GameClient(playerId, match.id, gui, messageBroadcaster);
			gameClient?.showState();
			return true;
		}
		case (is LeaftMatchMessage) {
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Left", false);
			}
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.showLeaveButton(null);
			return true;
		}
	}
}