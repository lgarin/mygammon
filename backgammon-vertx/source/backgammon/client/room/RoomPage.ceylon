import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.board {
	TableClient
}
import backgammon.client.browser {
	window,
	HTMLElement
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

import ceylon.regex {
	regex
}
import ceylon.time {
	now
}
shared class RoomPage() extends BasePage() {
	variable RoomId? roomId = null;
	value gui = RoomGui(window.document);
	variable TableClient? tableClient = null;
	variable EventBusClient? roomEventClient = null;
	variable EventBusClient? tableEventClient = null;
	variable EventBusClient? gameEventClient = null;
	value playerList = PlayerListModel(gui.hiddenClass);
	
	function extractRoomId() {
		if (!roomId exists) {
			value match = regex("/room/(\\w+)").find(window.location.href);
			if (exists match, exists id = match.groups[0]) {
				roomId = RoomId(id);
			}
		}
		return roomId;
	}
	
	isBoardPreview() => false;

	shared Boolean onButton(HTMLElement target) {
		
		if (target.id == gui.startButtonId) {
			window.location.\iassign("/start");
			return true;
		} else if (target.id == gui.playButtonId, exists currentRoomId = extractRoomId()) {
			window.location.\iassign("/room/``currentRoomId``/play");
			return true;
		} else if (target.id == gui.newButtonId, exists currentRoomId = extractRoomId()) {
			gui.hideJoinButton();
			gui.hideNewButton();
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
			gui.hideJoinButton();
			gui.hideNewButton();
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
		
		gameEventClient?.close();
		gameEventClient = null;
		tableEventClient?.close();
		tableEventClient = null;
		
		gui.showInitialGame();
		tableClient = TableClient(currentPlayerId, newTableId, gui, true, gameCommander);
		tableEventClient = EventBusClient("OutboundTableMessage-``newTableId``", onServerMessage, onServerError);
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
		gameEventClient?.close();
		gameEventClient = null;
		tableEventClient?.close();
		tableEventClient = null;
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
		
		if (exists currentTableClient = tableClient) {
			gameCommander(LeaveTableMessage(currentPlayerId, currentTableClient.tableId));
			window.location.\iassign("/room/``currentTableClient.tableId.roomId``");
			return true;
		} else {
			return false;
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
			gui.hideNewButton();
			gui.showLeaveButton();
			gui.hideJoinButton();
		} else {
			gui.showNewButton();
			gui.hideLeaveButton();
		}
		if (playerList.empty) {
			gui.showEmptyPlayerList();
		} else {
			gui.showPlayerList(playerList.toTemplateData(joinedTableId exists));
		}
		
		if (exists joinedTableId) {
			showTable(joinedTableId);
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
		gameEventClient?.close();
		tableEventClient?.close();
		roomEventClient?.close();

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
			gameEventClient?.close();
			gameEventClient = EventBusClient("OutboundGameMessage-``currentMatch.id``", onServerMessage, onServerError);
		} else if (is CreatedMatchMessage message) {
			gameEventClient?.close();
			gameEventClient = EventBusClient("OutboundGameMessage-``message.matchId``", onServerMessage, onServerError);
			if (message.hasPlayer(currentPlayerId)) {
				gui.showDialog("dialog-accept");
			}
		} else if (is JoinedTableMessage message, exists playerInfo = message.playerInfo) {
			playerList.updatePlayer(message.playerInfo); // TODO need?
			playerList.updateTable(message.playerId, message.tableId);
		} else if (is LeftTableMessage message) {
			playerList.updateTable(message.playerId, null);
		}
		
		//gui.showTableInfo(message.tableId, playerList.findPlayer(currentPlayerId));
		refreshPlayerList(message.tableId);
		
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
			gameEventClient?.close();
			
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
		roomEventClient = EventBusClient("OutboundRoomMessage-``currentRoomId``", onServerMessage, onServerError);
		roomCommander(RoomStateRequestMessage(currentPlayerState.playerId, currentRoomId));
		gui.showBeginState(currentPlayerState);
	}
	
	shared void run() {
		if (exists currentRoomId = extractRoomId(), exists currentPlayerId = extractPlayerId()) {
			roomCommander(PlayerStateRequestMessage(currentPlayerId, currentRoomId));
		} else {
			logout();
		}
	}
}