import backgammon.shared {
	PlayerInfo,
	TableStateResponseMessage,
	OutboundMatchMessage,
	TableId,
	MatchState,
	CreatedMatchMessage,
	OutboundTableMessage,
	LeftTableMessage,
	InboundMatchMessage,
	InboundTableMessage,
	PlayerId,
	OutboundGameMessage,
	InboundGameMessage,
	JoinedTableMessage,
	MatchEndedMessage
}
import backgammon.shared.game {
	player2Color,
	player1Color
}

import ceylon.time {
	Instant
}

shared final class TableClient(shared PlayerId playerId, shared TableId tableId, BoardGui gui, shared variable Boolean followNextMatch, Anything(InboundGameMessage|InboundMatchMessage|InboundTableMessage) messageBroadcaster) {
	
	variable MatchClient? matchClient = null;
	
	void showJoinedState(PlayerInfo playerInfo) {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, playerInfo.name, playerInfo.pictureUrl);
		gui.showPlayerMessage(player1Color, gui.joinedTextKey, false);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, gui.waitingTextKey, true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
	}
	
	void handleTableStateResponseMessage(TableStateResponseMessage message) {
		if (exists match = message.match) {
			matchClient = MatchClient(playerId, match, gui, messageBroadcaster);
		} else if (exists playerInfo = message.playerQueue.first) {
			showJoinedState(playerInfo);
		} else {
			gui.showInitialGame(gui.leftTextKey);
		}
	}
	
	shared Boolean handleTableMessage(OutboundTableMessage message) {
		if (tableId != message.tableId) {
			return false;
		}

		switch (message)
		case (is CreatedMatchMessage) {
			value match = MatchState(message.matchId, message.player1, message.player2);
			matchClient = MatchClient(playerId, match, gui, messageBroadcaster);
			followNextMatch = !message.hasPlayer(playerId);
			return true;
		}
		case (is LeftTableMessage) {
			if (!matchClient exists) {
				gui.showPlayerMessage(player1Color, gui.leftTextKey, false);
				gui.showCurrentPlayer(player1Color);
				gui.showPlayerMessage(player2Color, "", true);
				gui.hideSubmitButton();
				gui.hideUndoButton();
			}
			return true;
		}
		case (is TableStateResponseMessage) {
			handleTableStateResponseMessage(message);
			return true;
		}
		case (is JoinedTableMessage) {
			if (followNextMatch, !matchClient exists, exists playerInfo = message.playerInfo) {
				showJoinedState(playerInfo);
			}
			return true;
		}
		
	}
	
	shared Boolean handleMatchMessage(OutboundMatchMessage message) {
		if (tableId != message.tableId) {
			return false;
		}
		
		if (is MatchEndedMessage message, followNextMatch, exists currentMatchClient = matchClient) {
			matchClient = null;
			return currentMatchClient.handleMatchMessage(message);
		} else if (exists currentMatchClient = matchClient) {
			return currentMatchClient.handleMatchMessage(message);
		} else {
			return false;
		}
	}
	
	shared Boolean handleGameMessage(OutboundGameMessage message) {
		if (tableId != message.tableId) {
			return false;
		}

		if (exists currentMatchClient = matchClient) {
			return currentMatchClient.handleGameMessage(message);
		} else {
			return false;
		}
	}
	
	shared Boolean handleTimerEvent(Instant time) {
		if (exists currentMatchClient = matchClient) {
			return currentMatchClient.handleTimerEvent(time);
		} else {
			return true;
		}
	}
	
	shared Boolean handleSubmitEvent() {
		if (exists currentMatchClient = matchClient) {
			return currentMatchClient.handleSubmitEvent();
		} else {
			return false;
		}
	}
	
	shared GameClient? gameClient => matchClient?.gameClient;
	
	// TODO cleanup this function
	shared Boolean playerIsInMatch => matchClient?.match?.playerColor(playerId) exists && !(matchClient?.match?.gameEnded else false);
}