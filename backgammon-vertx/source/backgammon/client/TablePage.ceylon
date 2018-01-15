import backgammon.client.board {

	TableClient
}
import backgammon.shared {

	TableStateRequestMessage,
	TableId,
	PlayerDetailRequestMessage,
	PlayerStatisticOutputMessage,
	OutboundPlayerRosterMessage,
	PlayerDetailOutputMessage,
	MatchEndedMessage,
	RoomResponseMessage,
	OutboundGameMessage,
	OutboundMatchMessage
}
import ceylon.time {

	now
}
import backgammon.client.browser {

	HTMLElement,
	window
}
abstract shared class TablePage<out Gui>(shared Gui gui) extends BasePage() given Gui satisfies TableGui {
	variable EventBusClient? _eventBusClient = null; 
	variable TableClient? _tableClient = null;
	
	shared EventBusClient eventBusClient => _eventBusClient else (_eventBusClient = EventBusClient(onServerMessage, onServerError));
	
	shared TableClient? tableClient => _tableClient;
	
	shared void openTableClient(TableId tableId) {
		_tableClient = TableClient(currentPlayerId, tableId, gui, isBoardPreview(), gameCommander);
		eventBusClient.addAddress("OutboundTableMessage-``tableId``");
		gameCommander(TableStateRequestMessage(currentPlayerId, tableId, isBoardPreview()));
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
		if (target.id == gui.submitButtonId, exists currentTableClient = tableClient) {
			return currentTableClient.handleSubmitEvent();
		} else if (target.id == gui.undoButtonId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleUndoEvent();
		} else if (target.id == gui.jockerButtonId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleJockerEvent();
		} else if (target.id == gui.statusButtonId) {
			//window.location.\iassign("/status");
			rosterCommander(PlayerDetailRequestMessage(currentPlayerId));
			return true;
		} else if (target.id == gui.exitButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-logout");
			} else {
				logout();
			}
			return true;
		}
		
		return false;
	}
	
	shared actual Boolean handleRosterMessage(OutboundPlayerRosterMessage message) {
		switch (message)
		case (is PlayerStatisticOutputMessage) {
			return false;
		}
		case (is PlayerDetailOutputMessage) {
			value model = PlayerStatusModel(message.playerInfo, message.statistic, message.transactions);
			gui.showPlayerStatus(model.buildStatisticData(), model.buildTransactionList());
			return true;
		}
	}
	
	shared actual Boolean handleMatchMessage(OutboundMatchMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
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
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleGameMessage(message);
		} else {
			return false;
		}
	}
}