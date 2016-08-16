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
	variable GameClient? _gameClient = null;
	shared GameClient? gameClient => _gameClient;
	
	shared Boolean isMatchPlayer(PlayerId playerId) => match.playerColor(playerId) exists;
	
	GameClient initGameClient() {
		value result = GameClient(playerId, match.id, match.playerColor(playerId), gui, messageBroadcaster);
		_gameClient = result;
		return result;
	}
	
	void showMatchEnd(PlayerId leaverId, PlayerId winnerId) {
		gui.showCurrentPlayer(null);
		showMatchEndMessage(leaverId, winnerId, player1Color);
		showMatchEndMessage(leaverId, winnerId, player2Color);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.hideLeaveButton();
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
		gui.showCurrentPlayer(null);
		gui.showPlayerMessage(player1Color, "Loading...", true);
		gui.showPlayerMessage(player2Color, "Loading...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton();	}
	
	shared void showState() {
		_gameClient = null;
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
		gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
		if (exists leaverId = match.leaverId, exists winnerId = match.winnerId) { // TODO equivalent to gameEnded
			showMatchEnd(leaverId, winnerId);
		} else if (match.gameStarted) {
			showResumingGame();
			initGameClient();
			messageBroadcaster(GameStateRequestMessage(match.id, playerId));
		} else {
			showMatchBegin(match);
		}
	}

	shared void showMatchEndMessage(PlayerId leaverId, PlayerId winnerId, CheckerColor color) {
		value playerId = if (color == player1Color) then match.player1Id else match.player2Id;
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
	
	void showAccept(AcceptedMatchMessage message) {
		match.markReady(message.playerId);
		if (exists color = match.playerColor(message.playerId)) {
				gui.showPlayerMessage(color, "Ready", false);
			}
		if (message.playerId == playerId) {
				gui.showCurrentPlayer(null);
				gui.hideSubmitButton();
			}
	}
	
	shared Boolean handleMatchMessage(OutboundMatchMessage message) {
		if (message.matchId != match.id) {
			return false;
		}
		
		switch (message)
		case (is AcceptedMatchMessage) {
			showAccept(message);
			return true;
		}
		case (is MatchEndedMessage) {
			_gameClient = null;
			showMatchEnd(message.playerId, message.winnerId);
			return true;
		}
	}
	 
	shared Boolean handleGameMessage(OutboundGameMessage message) {
	 	if (match.id != message.matchId) {
	 		return false;
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