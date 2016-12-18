import backgammon.shared {
	MatchState,
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

shared final class MatchClient(PlayerId playerId, shared MatchState match, BoardGui gui, Anything(InboundGameMessage|InboundMatchMessage) messageBroadcaster) {
	
	shared MatchId matchId = match.id;
	
	variable GameClient? _gameClient = null;
	shared GameClient? gameClient => _gameClient;
	
	shared Boolean playerIsInMatch => match.playerColor(playerId) exists && !match.gameEnded;
	
	function initGameClient() {
		value result = GameClient(playerId, match.id, match.playerColor(playerId), gui, messageBroadcaster);
		_gameClient = result;
		return result;
	}
	
	void showMatchEndMessage(PlayerId leaverId, PlayerId winnerId, CheckerColor color) {
		value playerId = if (color == player1Color) then match.player1Id else match.player2Id;
		if (playerId == winnerId) {
			gui.showPlayerMessage(color, gui.winnerTextKey, false);
			gui.showCurrentPlayer(color);
		} else if (playerId == leaverId) {
			gui.showPlayerMessage(color, gui.leftTextKey, false);
		} else if (leaverId == systemPlayerId) {
			gui.showPlayerMessage(color, gui.timeoutTextKey, false);
		} else if (winnerId == systemPlayerId) {
			gui.showPlayerMessage(color, gui.tieTextKey, false);
		} else {
			gui.showPlayerMessage(color, "", false);
		}
	}
	
	void showMatchEnd(PlayerId leaverId, PlayerId winnerId, Integer score) {
		gui.showCurrentPlayer(null);
		showMatchEndMessage(leaverId, winnerId, player1Color);
		showMatchEndMessage(leaverId, winnerId, player2Color);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		if (playerId == winnerId) {
			gui.showDialog("dialog-won", {"game-score" -> score.string});
		} else if (exists looserId = match.opponentId(winnerId), playerId == looserId) {
			gui.showDialog("dialog-lost");
		}
	}
	
	void showMatchBegin(MatchState match) {
		gui.showPlayerMessage(player1Color, match.player1Ready then gui.readyTextKey else gui.beginTexKey, !match.player1Ready);
		gui.showPlayerMessage(player2Color, match.player2Ready then gui.readyTextKey else gui.beginTexKey, !match.player2Ready);
		gui.showCurrentPlayer(match.playerColor(playerId));
		if (match.mustStartMatch(playerId)) {
			gui.showSubmitButton(gui.playTextKey);
		} else {
			gui.hideSubmitButton();
		}
		gui.hideUndoButton();
	}
	
	void showResumingGame() {
		gui.showCurrentPlayer(null);
		gui.showPlayerMessage(player1Color, gui.loadingTextKey, true);
		gui.showPlayerMessage(player2Color, gui.loadingTextKey, true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
	}
	
	void showAccept(AcceptedMatchMessage message) {
		match.markReady(message.playerId);
		if (exists color = match.playerColor(message.playerId)) {
			gui.showPlayerMessage(color, gui.readyTextKey, false);
		}
		if (message.playerId == playerId) {
			gui.showCurrentPlayer(null);
			gui.hideSubmitButton();
		}
	}
	
	void showState() {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
		gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
		if (match.gameEnded, exists leaverId = match.leaverId, exists winnerId = match.winnerId) {
			showMatchEnd(leaverId, winnerId, match.score);
		} else if (match.gameStarted) {
			showResumingGame();
			initGameClient();
			messageBroadcaster(GameStateRequestMessage(match.id, playerId));
		} else {
			showMatchBegin(match);
		}
	}
	
	// constructor
	showState();
	
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
			showMatchEnd(message.playerId, message.winnerId, message.score);
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