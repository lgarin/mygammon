import backgammon.common {
	MatchState,
	PlayerInfo,
	InboundGameMessage,
	GameStateRequestMessage,
	PlayerId,
	OutboundMatchMessage,
	OutboundGameMessage,
	LeftMatchMessage,
	AcceptedMatchMessage,
	CreatedGameMessage,
	MatchId,
	InboundMatchMessage,
	AcceptMatchMessage
}
import backgammon.game {
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
			showWin(match.winnerColor);
		} else {
			showMatchBegin(match);
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
		case (is LeftMatchMessage) {
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Left", true);
			}
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.hideLeaveButton();
			return true;
		}
		case (is CreatedGameMessage) {
			if (gameClient is Null) {
				initGameClient().showState();
			}
			return true;
		}
	}
	 
	shared Boolean handleGameMessage(OutboundGameMessage message) {
	 	if (match.id != message.matchId) {
	 		return true;
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