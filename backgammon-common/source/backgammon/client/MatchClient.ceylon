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
	CreatedGameMessage
}
import backgammon.game {
	player2Color,
	player1Color,
	CheckerColor
}

import ceylon.time {
	Instant,
	now
}
shared final class MatchClient(PlayerInfo player, MatchState match, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	value playerId = PlayerId(player.id);
	variable GameClient? gameClient = null;
	value timeout = now().plus(match.remainingJoinTime);
	variable Boolean player1Ready = match.player1Ready;
	variable Boolean player2Ready = match.player2Ready; 
	
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
		gui.showPlayerMessage(player1Color, match.player1Ready then "Ready" else gui.formatPeriod(match.remainingJoinTime), !match.player1Ready);
		gui.showPlayerMessage(player2Color, match.player2Ready then "Ready" else gui.formatPeriod(match.remainingJoinTime), !match.player2Ready);
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
	
	shared Boolean handleMatchMessage(OutboundMatchMessage message) {
		if (message.matchId != match.id) {
			return false;
		}
		
		switch (message)
		case (is AcceptedMatchMessage) {
			if (message.playerId == match.player1Id) {
				player1Ready = true;
			} else if (message.playerId == match.player2Id) {
				player2Ready = true;
			}
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Ready", false);
				gui.hideSubmitButton();
			}
			return true;
		}
		case (is LeftMatchMessage) {
			if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Left", false);
			}
			// TODO show winner
			//gameClient?.endGame();
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.showLeaveButton(null);
			return true;
		}
		case (is CreatedGameMessage) {
			gameClient = GameClient(playerId, match.id, gui, messageBroadcaster);
			gameClient?.showState();
			return true;
		}
	}
	 
	shared Boolean handleGameMessage(OutboundGameMessage message) {
	 	if (match.id != message.matchId) {
	 		return false;
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
			value remainingTime = time.durationTo(timeout);
			if (!player1Ready) {
				gui.showPlayerMessage(player1Color, gui.formatPeriod(remainingTime), true);
			}
			if (!player2Ready) {
				gui.showPlayerMessage(player2Color, gui.formatPeriod(remainingTime), true);
			}
			return true;
		}
	}
}