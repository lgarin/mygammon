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
	LeaveTableMessage,
	InboundTableMessage,
	PlayerId,
	OutboundGameMessage,
	InboundGameMessage
}
import backgammon.shared.game {
	player2Color,
	player1Color
}
import ceylon.time {
	Instant
}

shared final class TableClient(TableId tableId, PlayerInfo playerInfo, GameGui gui, Anything(InboundGameMessage|InboundMatchMessage|InboundTableMessage) messageBroadcaster) {
	
	value playerId = PlayerId(playerInfo.id);
	variable MatchClient? matchClient = null;
	
	shared void showState() {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, playerInfo.name, playerInfo.pictureUrl);
		gui.showPlayerMessage(player1Color, "Joined", false);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton();
	}
	
	void handleTableStateResponseMessage(TableStateResponseMessage message) {
		if (exists match = message.match) {
			matchClient = MatchClient(playerInfo, match, gui, messageBroadcaster);
			matchClient?.showState();
		} else {
			// TODO player may not be on table
			showState();
		}
	}
	
	shared Boolean handleTableMessage(OutboundTableMessage message) {
		if (tableId != message.tableId) {
			return false;
		}

		switch (message)
		case (is CreatedMatchMessage) {
			value match = MatchState(message.matchId, message.player1, message.player2);
			matchClient = MatchClient(playerInfo, match, gui, messageBroadcaster);
			matchClient?.showState();
			return true;
		}
		case (is LeftTableMessage) {
			if (exists match = matchClient?.match, exists color = match.playerColor(playerId), !match.gameStarted) {
				gui.showPlayerMessage(color, "Left", false);
				gui.showCurrentPlayer(color);
				gui.showPlayerMessage(color.oppositeColor, "", true);
			} else if (playerId == message.playerId) {
				gui.showPlayerMessage(player1Color, "Left", false);
				gui.showCurrentPlayer(player1Color);
				gui.showPlayerMessage(player2Color, "", true);
			}
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.hideLeaveButton();
			return true;
		}
		case (is TableStateResponseMessage) {
			handleTableStateResponseMessage(message);
			return true;
		}
		else {
			// ignore other messages
			return true;
		}
	}
	
	shared Boolean handleMatchMessage(OutboundMatchMessage message) {
		if (tableId != message.tableId) {
			return false;
		}
		
		if (exists currentMatchClient = matchClient) {
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
	
	shared Boolean handleLeaveEvent() {
		gui.hideLeaveButton();
		messageBroadcaster(LeaveTableMessage(playerId, tableId));
		return true;
	}
	
	shared GameClient? gameClient => matchClient?.gameClient;
}