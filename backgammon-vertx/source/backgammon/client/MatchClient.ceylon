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
	MatchEndedMessage,
	systemPlayerId
}
import backgammon.shared.game {
	player2Color,
	player1Color,
	CheckerColor
}

import ceylon.time {
	Instant
}

shared final class MatchClient(PlayerInfo player, shared MatchState match, GameGui gui, Anything(InboundGameMessage|InboundMatchMessage) messageBroadcaster) {
	
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
			gui.showCurrentPlayer(currentColor);
			gui.showPlayerMessage(currentColor.oppositeColor, "", false);
		} else {
			gui.showPlayerMessage(player1Color, "Tie", false);
			gui.showPlayerMessage(player2Color, "Tie", false);
			gui.showCurrentPlayer(null);
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

	shared void showMatchEndMessage(PlayerId leaverId, PlayerId winnerId, CheckerColor color) {
		value playerId = color == player1Color then match.player1Id else match.player2Id;
		if (playerId == winnerId) {
			gui.showPlayerMessage(color, "Winner", false);
			gui.showCurrentPlayer(color);
		} else if (playerId == leaverId) {
			gui.showPlayerMessage(color, "Left", false);
		} else if (leaverId == systemPlayerId) {
			gui.showPlayerMessage(color, "Timeout", false);
		} else if (winnerId == systemPlayerId) {
			gui.showPlayerMessage(color, "Tie", false);
		} else {
			gui.showPlayerMessage(color, "", false);
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
				gui.showCurrentPlayer(null);
				gui.hideSubmitButton();
			}
			return true;
		}
		case (is MatchEndedMessage) {
			showMatchEndMessage(message.playerId, message.winnerId, player1Color);
			showMatchEndMessage(message.playerId, message.winnerId, player2Color);
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