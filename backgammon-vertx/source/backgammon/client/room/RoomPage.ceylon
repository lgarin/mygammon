import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.board {
	TableClient
}
import backgammon.client.browser {
	window,
	HTMLElement,
	document
}
import backgammon.shared {
	RoomId,
	OutboundRoomMessage,
	PlayerListMessage,
	MatchEndedMessage,
	OutboundMatchMessage,
	RoomResponseMessage,
	OutboundTableMessage,
	TableStateResponseMessage,
	OutboundGameMessage,
	TableStateRequestMessage,
	PlayerId,
	LeaveTableMessage,
	RoomStateRequestMessage,
	FindEmptyTableMessage,
	FoundEmptyTableMessage,
	TableId,
	JoinTableMessage,
	PlayerStateRequestMessage,
	CreatedMatchMessage,
	JoinedTableMessage,
	LeftTableMessage,
	PlayerState,
	PlayerStateMessage
}

import ceylon.time {
	now
}
shared final class RoomPage() extends BasePage() {
	variable RoomId? roomId = null;
	value gui = RoomGui(document);
	variable TableClient? tableClient = null;
	variable EventBusClient? eventBusClient = null;
	value playerList = PlayerListModel(gui.hiddenClass);
	
	function extractRoomId() {
		if (!roomId exists) {
			if (exists id = splitString(window.location.href, "/room/", "#")) {
				roomId = RoomId(id);
			} else if (exists id = splitString(window.location.href, "/room/")) {
				roomId = RoomId(id);
			}
		}
		return roomId;
	}
	
	isBoardPreview() => true;

	shared Boolean onButton(HTMLElement target) {
		
		if (target.id == gui.startButtonId) {
			window.location.\iassign("/start");
			return true;
		} else if (target.id == gui.playButtonId, exists currentRoomId = extractRoomId()) {
			window.location.\iassign("/room/``currentRoomId``/play");
			return true;
		} else if (target.id == gui.newButtonId, exists currentRoomId = extractRoomId()) {
			roomCommander(FindEmptyTableMessage(currentPlayerId, currentRoomId));
			return true;
		} else if (target.id == gui.leaveButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-leave");
				return true;
			} else {
				return onLeaveConfirmed();
			}
		} else if (target.id == gui.joinButtonId, exists currentRoomId = extractRoomId(), exists tableId = tableClient?.tableId) {
			gameCommander(JoinTableMessage(currentPlayerId, tableId));
			return true;
		} else if (target.id == gui.exitButtonId, exists currentRoomId = extractRoomId()) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-logout");
			} else {
				logout();
			}
			return true;
		} else {
			return false;
		}
	}

	function showTable(TableId newTableId) {
		gui.showTableInfo(newTableId, playerList.findPlayer(currentPlayerId));
		
		if (exists currentTableClient = tableClient, currentTableClient.tableId == newTableId) {
			return true;
		}
		
		eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
		eventBusClient?.removeAddresses((a) => a.startsWith("OutboundTableMessage-"));
		
		gui.showInitialGame();
		tableClient = TableClient(currentPlayerId, newTableId, gui, true, gameCommander);
		eventBusClient?.addAddress("OutboundTableMessage-``newTableId``");
		gameCommander(TableStateRequestMessage(currentPlayerId, newTableId, true));
		gui.showTablePreview();
		return true;
	}
	
	shared Boolean onLogoutConfirmed() {
		logout();
		return true;
	}
	
	void hideTable() {
		tableClient = null;
		eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
		eventBusClient?.removeAddresses((a) => a.startsWith("OutboundTableMessage-"));
		gui.hideTablePreview();
	}
	
	shared Boolean onPlayerClick(String playerId) {

		if (exists playerState = playerList.findPlayer(currentPlayerId), playerState.tableId exists) {
			return false;
		} else if (exists playerState = playerList.findPlayer(PlayerId(playerId)), exists tableId = playerState.tableId) {
			return showTable(tableId);
		} else {
			hideTable();
			return true;
		}
	}
	
	shared Boolean onLeaveConfirmed() {
		
		if (exists playerState = playerList.findPlayer(currentPlayerId), exists tableId = playerState.tableId) {
			gameCommander(LeaveTableMessage(currentPlayerId, tableId));
			return true;
		} else {
			// player is only viewing the table
			refreshPlayerList(null);
			return true;
		}
	}
	
	shared Boolean onAcceptMatch() {
		
		if (exists currentTableClient = tableClient) {
			window.location.\iassign("/room/``currentTableClient.tableId.roomId``/table/``currentTableClient.tableId.table``/play");
			return true;
		} else {
			return false;
		}
	}
	
	void refreshPlayerList(TableId? joinedTableId) {
		if (exists joinedTableId) {
			showTable(joinedTableId);
		} else if (exists currentTableClient = tableClient) {
			showTable(currentTableClient.tableId);
		}
		
		if (exists joinedTableId) {
			gui.hideNewButton();
			gui.showLeaveButton();
		} else {
			gui.showNewButton();
			gui.hideLeaveButton();
		}
		if (playerList.empty) {
			gui.showEmptyPlayerList();
		} else {
			gui.showPlayerList(playerList.toTemplateData(joinedTableId exists));
		}
	}
	
	shared Boolean onTimer() {
		if (exists currentClient = tableClient) {
			return currentClient.handleTimerEvent(now());
		} else {
			return true;
		}
	}
	
	void logout() {
		window.location.\iassign("/logout");
	}
	
	shared actual Boolean handleRoomMessage(OutboundRoomMessage message) {
		
		if (!message.success) {
			logout();
			return true;
		}
		
		if (is PlayerListMessage message) {
			playerList.update(message);
			if (!playerList.findPlayer(currentPlayerId) exists) {
				logout();
				return true;
			} else {
				refreshPlayerList(playerList.findTable(currentPlayerId));
				return true;
			}
		} else if (is FoundEmptyTableMessage message) {
			if (exists tableId = message.tableId) {
				refreshPlayerList(tableId);
				return true;
			} else {
				return false;
			}
		} else if (is PlayerStateMessage message) {
			if (exists state = message.state) {
				login(state, message.roomId);
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleTableMessage(OutboundTableMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			// TODO some changes may occur on the state between the response and the registration
			eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
			eventBusClient?.addAddress("OutboundGameMessage-``currentMatch.id``");
		} else if (is CreatedMatchMessage message) {
			eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
			eventBusClient?.addAddress("OutboundGameMessage-``message.matchId``");
			if (message.hasPlayer(currentPlayerId)) {
				gui.showDialog("dialog-accept");
			}
		} else if (is JoinedTableMessage message, exists playerInfo = message.playerInfo) {
			playerList.updatePlayer(message.playerInfo); // TODO need?
			playerList.updateTable(message.playerId, message.tableId);
		} else if (is LeftTableMessage message) {
			playerList.updateTable(message.playerId, null);
		}
		
		refreshPlayerList(playerList.findTable(currentPlayerId));
		
		if (exists currentClient = tableClient) {
			return currentClient.handleTableMessage(message);
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleMatchMessage(OutboundMatchMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is MatchEndedMessage message) {
			eventBusClient?.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
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
	
	void login(PlayerState currentPlayerState, RoomId currentRoomId) {
		print(currentPlayerState.toJson());
		eventBusClient?.addAddress("OutboundRoomMessage-``currentRoomId``");
		roomCommander(RoomStateRequestMessage(currentPlayerState.playerId, currentRoomId));
		gui.showBeginState(currentPlayerState);
	}
	
	shared void run() {
		eventBusClient = EventBusClient(onServerMessage, onServerError);
		if (exists currentRoomId = extractRoomId(), exists currentPlayerId = extractPlayerId()) {
			roomCommander(PlayerStateRequestMessage(currentPlayerId, currentRoomId));
		} else {
			logout();
		}
	}
}