import backgammon.client.board {

	TableClient
}
import backgammon.shared {

	TableStateRequestMessage,
	TableId,
	OutboundPlayerRosterMessage,
	MatchEndedMessage,
	StatusResponseMessage,
	OutboundGameMessage,
	OutboundMatchMessage,
	OutboundScoreBoardMessage,
	OutboundRoomMessage,
	PlayerStateMessage,
	OutboundTableMessage,
	OutboundChatRoomMessage,
	RoomId
}
import ceylon.time {

	now
}
import backgammon.client.browser {

	HTMLElement,
	window
}
import backgammon.client.chat {

	ChatClient
}
abstract shared class TablePage<out Gui>(shared Gui gui) extends BasePage() given Gui satisfies TableGui {
	variable EventBusClient? _eventBusClient = null; 
	variable TableClient? _tableClient = null;
	variable ChatClient? _chatClient = null;
	
	shared EventBusClient eventBusClient => _eventBusClient else (_eventBusClient = EventBusClient(onServerMessage, onServerError));
	
	shared TableClient? tableClient => _tableClient;
	
	shared ChatClient? chatClient => _chatClient;
	
	shared formal RoomId? extractRoomId();
	
	shared void openTableClient(TableId tableId) {
		_tableClient = TableClient(currentPlayerId, tableId, gui, isBoardPreview(), gameCommander);
		eventBusClient.addAddress("OutboundTableMessage-``tableId``");
		gameCommander(TableStateRequestMessage(currentPlayerId, tableId, isBoardPreview()));
	}
	
	shared void openChatClient(RoomId roomId) {
		_chatClient = ChatClient(currentPlayerId, roomId, gui, chatCommander);
		eventBusClient.addAddress("OutboundRoomMessage-``roomId``");
	}
	
	shared void closeTableClient() {
		_tableClient = null;
		_eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
		_eventBusClient?.removeAddresses((a) => a.startsWith("OutboundTableMessage-"));
	}
	
	shared Boolean onTimer() {
		if (exists currentClient = tableClient) {
			return currentClient.handleTimerEvent(now());
		} else {
			return true;
		}
	}
	
	shared void logout() {
		window.location.\iassign("/logout");
	}
	
	shared void restart() {
		window.location.\iassign("/start");
	}
	
	shared Boolean onLogoutConfirmed() {
		logout();
		return true;
	}
	
	shared default Boolean onButton(HTMLElement target) {
		if (target.id == gui.submitButtonId, exists client = tableClient) {
			return client.handleSubmitEvent();
		} else if (target.id == gui.undoButtonId, exists client = tableClient?.gameClient) {
			return client.handleUndoEvent();
		} else if (target.id == gui.jokerButtonId, exists client = tableClient?.gameClient) {
			return client.handleJokerEvent();
		} else if (target.id == gui.jokerDiceNr1Id || target.id == gui.jokerDiceNr2Id, exists client = tableClient?.gameClient) {
			return client.handleJokerDiceEvent(target);
		} else if (target.id == gui.chatButtonId, exists client = chatClient) {
			return client.toggleHistory();
		} else if (target.id == gui.chatPostButtonId, exists client = chatClient) {
			return client.postMessage();
		} else if (target.id == gui.exitButtonId) {
			if (exists client = tableClient, client.playerIsInMatch) {
				gui.showDialog("dialog-logout");
			} else {
				logout();
			}
			return true;
		}
		
		return false;
	}
	
	shared actual default Boolean handleRosterMessage(OutboundPlayerRosterMessage message) {
		return false;
	}
	
	shared actual default Boolean handleScoreMessage(OutboundScoreBoardMessage message) {
		return false;
	}
	
	shared actual default Boolean handleRoomMessage(OutboundRoomMessage message) {
		
		if (is PlayerStateMessage message, !message.success) {
			logout();
			return true;
		} else if (!message.success) {
			return false;
		} else {
			return true;
		}
	}
	
	shared actual default Boolean handleTableMessage(OutboundTableMessage message) {
		
		if (is StatusResponseMessage message, !message.success) {
			return false;
		} else {
			return true;
		}
	}

	shared actual Boolean handleMatchMessage(OutboundMatchMessage message) {
		
		if (is StatusResponseMessage message, !message.success) {
			return false;
		}
		
		if (is MatchEndedMessage message) {
			eventBusClient.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
			if (!isBoardPreview()) {
				eventBusClient.removeAddresses((a) => a.startsWith("OutboundTableMessage-"));
			}
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleMatchMessage(message);
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleGameMessage(OutboundGameMessage message) {
		
		if (is StatusResponseMessage message, !message.success) {
			return false;
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleGameMessage(message);
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleChatMessage(OutboundChatRoomMessage message) {
		
		if (exists currentClient = chatClient) {
			return currentClient.handleChatMessage(message);
		} else {
			return false;
		}
	}
}