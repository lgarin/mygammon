import backgammon.common {
	PlayerInfo,
	TableStateResponseMessage,
	InboundGameMessage,
	OutboundMatchMessage,
	TableId,
	MatchState,
	CreatedMatchMessage,
	OutboundRoomMessage,
	OutboundTableMessage,
	OutboundGameMessage,
	LeftTableMessage,
	LeftMatchMessage,
	InboundMatchMessage
}
import backgammon.game {
	player2Color,
	player1Color
}

import ceylon.time {
	Instant
}

shared final class TableClient(TableId tableId, PlayerInfo playerInfo, GameGui gui, Anything(InboundGameMessage|InboundMatchMessage) messageBroadcaster) {
	
	variable MatchClient? matchClient = null;
	
	shared void showState() {
		gui.showEmptyGame();
		gui.showPlayerInfo(player1Color, playerInfo.name, playerInfo.pictureUrl);
		gui.showPlayerMessage(player1Color, "Joined", false);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	
	void handleTableStateResponseMessage(TableStateResponseMessage message) {
		gui.showEmptyGame();
		
		if (exists match = message.match) {
			matchClient = MatchClient(playerInfo, match, gui, messageBroadcaster);
			matchClient?.showState();
		} else {
			showState();
		}
	}
	
	
	shared Boolean handleRoomMessage(OutboundRoomMessage message) {
		if (!message.success) {
			return false;
		}
		switch (message)
		case (is TableStateResponseMessage) {
			handleTableStateResponseMessage(message);
			return true;
		}
		else {
			// ignore other messages
			return true;
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
			if (exists currentMatchClient = matchClient) {
				return currentMatchClient.handleMatchMessage(LeftMatchMessage(message.playerId, currentMatchClient.matchId));
			} else {
				return true;
			}
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
}