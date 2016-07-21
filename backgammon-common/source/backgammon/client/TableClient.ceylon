import backgammon.common {
	PlayerInfo,
	TableStateResponseMessage,
	RoomResponseMessage,
	InboundGameMessage,
	JoiningMatchMessage,
	OutboundMatchMessage,
	LeaftMatchMessage,
	StartMatchMessage,
	TableId
}
import backgammon.game {
	player2Color,
	player1Color
}

shared final class TableClient(TableId tableId, PlayerInfo playerInfo, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
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
	
	
	shared Boolean handleRoomMessage(RoomResponseMessage message) {
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
	
	
	shared Boolean handleTableMessage(OutboundMatchMessage message) {
		if (tableId != message.tableId) {
			return false;
		}
		
		if (exists currentMatchClient = matchClient) {
			return currentMatchClient.handleTableMessage(message);
		}
		
		switch (message)
		case (is JoiningMatchMessage) {
			// TODO match state
			//matchClient = MatchClient(playerInfo, message.state, gui, messageBroadcaster);
			matchClient?.showState();
			return true;
		}
		case (is StartMatchMessage) {
			return false;
		}
		case (is LeaftMatchMessage) {
			return false;
		}
	}
}