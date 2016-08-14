import backgammon.shared {
	MatchState,
	PlayerInfo,
	PlayerId,
	OutboundMatchMessage,
	AcceptedMatchMessage,
	MatchId,
	InboundMatchMessage,
	AcceptMatchMessage,
	OutboundGameMessage,
	GameStateRequestMessage,
	InboundGameMessage,
	MatchEndedMessage
}
import backgammon.shared.game {
	player2Color,
	player1Color,
	CheckerColor
}

import ceylon.time {
	Instant
}

shared final class MatchClient(PlayerInfo player, MatchState match, GameGui gui, Anything(InboundGameMessage|InboundMatchMessage) messageBroadcaster) {
	
	shared MatchId matchId = match.id;
	
	value playerId = PlayerId(player.id);
	variable GameClient? gameClientVar = null;
	shared GameClient? gameClient => gameClientVar;
	
	shared Boolean isMatchPlayer(PlayerId playerId) => match.playerColor(playerId) exists;
	
	GameClient initGameClient() {
		value result = GameClient(playerId, match.id, match.playerColor(playerId), gui, messageBroadcaster);
		gameClientVar = result;
		return result;
	}
	
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
		gui.showLeaveButton();
	}
	
	void showMatchBegin(MatchState match) {
		gui.showPlayerMessage(player1Color, match.player1Ready then "Ready" else "Play?", !match.player1Ready);
		gui.showPlayerMessage(player2Color, match.player2Ready then "Ready" else "Play?", !match.player2Ready);
		gui.showCurrentPlayer(match.playerColor(playerId));
		if (match.mustStartMatch(playerId)) {
			gui.showSubmitButton("Play");
		} else {
			gui.hideSubmitButton();
		}
		gui.hideUndoButton();
		gui.showLeaveButton();
	}
	
	void showResumingGame() {
		gui.showPlayerMessage(player1Color, "Loading...", true);
		gui.showPlayerMessage(player2Color, "Loading...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton();	}
	
	shared void showState() {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
		gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
		if (match.gameStarted) {
			showResumingGame();
			initGameClient();
			messageBroadcaster(GameStateRequestMessage(match.id, playerId));
		} else if (match.gameEnded) {
			// TODO add lastPayerId to state in order to show the same messages as showMatchEndMessage
			showWin(match.winnerColor);
		} else {
			showMatchBegin(match);
		}
	}
	
	shared void showLeft(PlayerId playerId) {
		if (exists color = match.playerColor(playerId)) {
			gui.showPlayerMessage(color, "Left", false);
			gui.showPlayerMessage(color.oppositeColor, "", false);
		}
	}
	
	shared void showMatchEndMessage(MatchEndedMessage message, CheckerColor color) {
		value playerId = color == player1Color then match.player1Id else match.player2Id;
		if (message.isWinner(playerId)) {
			gui.showPlayerMessage(color, "Winner", false);
		} else if (message.isLeaver(playerId)) {
			gui.showPlayerMessage(color, "Left", false);
		} else if (message.isTimeout(playerId)) {
			gui.showPlayerMessage(color, "Timeout", false);
		} else {
			gui.showPlayerMessage(color, "Tie", false);
		}
	}
	
	shared Boolean handleMatchMessage(OutboundMatchMessage message) {
		if (message.matchId != match.id) {
			return true;
		}
		
		switch (message)
		case (is AcceptedMatchMessage) {
			match.markReady(message.playerId);
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Ready", false);
			}
			if (message.playerId == playerId) {
				gui.hideSubmitButton();
			}
			return true;
		}
		case (is MatchEndedMessage) {
			showMatchEndMessage(message, player1Color);
			showMatchEndMessage(message, player2Color);
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.hideLeaveButton();
			return true;
		}
	}
	 
	shared Boolean handleGameMessage(OutboundGameMessage message) {
	 	if (match.id != message.matchId) {
	 		return true;
	 	}
	 	
	 	if (gameClient is Null) {
	 		initGameClient().showState();
	 	}
	 	
	 	if (exists currentGameClient = gameClient) {
	 		return currentGameClient.handleGameMessage(message);
	 	} else {
	 		return false;
	 	}
	 }
	
	shared Boolean handleTimerEvent(Instant time) {
		
		if (exists currentGameClient = gameClient) {
			return currentGameClient.handleTimerEvent(time);
		} else {
			return true;
		}
	}
	
	shared Boolean handleSubmitEvent() {
		if (exists currentGameClient = gameClient) {
			return currentGameClient.handleSubmitEvent();
		} else if (match.mustStartMatch(playerId)) {
			gui.hideSubmitButton();
			messageBroadcaster(AcceptMatchMessage(playerId, matchId));
			return true;
		} else {
			return false;
		}
	}
}