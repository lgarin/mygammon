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
	parseOutboundRoomMessage,
	OutboundRoomMessage,
	PlayerListMessage,
	parseOutboundGameMessage,
	parseOutboundTableMessage,
	parseOutboundMatchMessage,
	MatchEndedMessage,
	OutboundMatchMessage,
	RoomResponseMessage,
	OutboundTableMessage,
	TableStateResponseMessage,
	OutboundGameMessage,
	TableStateRequestMessage,
	PlayerId,
	InboundTableMessage,
	InboundGameMessage,
	InboundMatchMessage,
	UndoMovesMessage,
	LeaveTableMessage,
	EndMatchMessage,
	formatRoomMessage,
	StartGameMessage,
	EndGameMessage,
	AcceptMatchMessage,
	MakeMoveMessage,
	EndTurnMessage,
	PlayerBeginMessage,
	GameStateRequestMessage,
	RoomStateRequestMessage,
	InboundRoomMessage,
	EnterRoomMessage,
	LeaveRoomMessage,
	FindMatchTableMessage,
	FindEmptyTableMessage,
	FoundEmptyTableMessage,
	TableId,
	PlayerInfo,
	JoinTableMessage,
	LeftTableMessage,
	JoinedTableMessage,
	PlayerStateRequestMessage,
	PlayerStateMessage,
	CreatedMatchMessage
}

import ceylon.json {
	Object
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
	
	variable Integer queueSize = 0;
	
	function extractRoomId() {
		if (!roomId exists) {
			value match = regex("/room/(\\w+)").find(window.location.href);
			if (exists match, exists id = match.groups[0]) {
				roomId = RoomId(id);
			}
		}
		return roomId;
	}

	shared Boolean onButton(HTMLElement target) {
		
		if (target.id == gui.startButtonId) {
			window.location.\iassign("/start");
			return true;
		} else if (target.id == gui.playButtonId, exists currentRoomId = extractRoomId()) {
			window.location.\iassign("/room/``currentRoomId``/play");
			return true;
		} else if (target.id == gui.newButtonId, exists currentRoomId = extractRoomId(), exists currentPlayerInfo = extractPlayerInfo()) {
			roomCommander(FindEmptyTableMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
			return true;
		} else if (target.id == gui.leaveButtonId, exists currentTableClient = tableClient) {
			return currentTableClient.handleLeaveEvent();
		} else if (target.id == gui.sitButtonId, exists currentRoomId = extractRoomId(), exists tableId = tableClient?.tableId, exists currentPlayerInfo = extractPlayerInfo()) {
			gameCommander(JoinTableMessage(PlayerId(currentPlayerInfo.id), tableId));
			return true;
		} else if (target.id == gui.exitButtonId, exists currentRoomId = extractRoomId(), exists currentPlayerInfo = extractPlayerInfo()) {
			roomCommander(PlayerStateRequestMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
			return true;
		} else {
			return false;
		}
	}
	
	void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
		print(formatRoomMessage(message));
		switch (message)
		case (is AcceptMatchMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/accept");
		}
		case (is StartGameMessage) {
		}
		case (is EndMatchMessage) {
		}
		case (is PlayerBeginMessage) {
		}
		case (is MakeMoveMessage) {
		}
		case (is UndoMovesMessage) {
		}
		case (is EndTurnMessage) {
		}
		case (is EndGameMessage) {
		}
		case (is GameStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/state");
		}
		case (is LeaveTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/leave");
		}
		case (is TableStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/state");
		}
		case (is JoinTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/join");
		}
	}
	
	function showTable(TableId newTableId, PlayerInfo playerInfo) {
		if (exists currentTableClient = tableClient, currentTableClient.tableId == newTableId) {
			return true;
		}
		
		gameEventClient?.close();
		gameEventClient = null;
		tableEventClient?.close();
		tableEventClient = null;
		
		gui.showInitialGame();
		tableClient = TableClient(newTableId, playerInfo, gui, gameCommander);
		tableEventClient = EventBusClient("OutboundTableMessage-``newTableId``", onServerMessage, onServerError);
		// TODO api do not use the playerId
		// TODO add a flag to request message
		gameCommander(TableStateRequestMessage(PlayerId(playerInfo.id), newTableId));
		gui.showTablePreview();
		gui.showSitButton();
		gui.showQueueSize(null);
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

		if (exists playerState = playerList.findPlayer(playerId), exists tableId = playerState.tableId) {
			return showTable(tableId, playerState.toPlayerInfo());
		} else {
			hideTable();
			return true;
		}
	}
	
	shared Boolean onLeaveConfirmed() {
		
		if (exists currentTableClient = tableClient) {
			currentTableClient.handleLeaveEvent();
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean onAcceptMatch() {
		
		if (exists currentTableClient = tableClient) {
			// TODO
			//gameCommander(AcceptMatchMessage(playerId, matchId));
			window.location.\iassign("/room/``currentTableClient.tableId.roomId``/table/``currentTableClient.tableId.table``");
			return true;
		} else {
			return false;
		}
	}
	
	void refreshPlayerList(TableId? joinedTableId) {
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
		
		if (exists joinedTableId, exists playerInfo = extractPlayerInfo()) {
			showTable(joinedTableId, playerInfo);
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
		gameEventClient = null;
		
		tableEventClient?.close();
		tableEventClient = null;
		
		roomEventClient?.close();
		roomEventClient = null;
		
		window.location.\iassign("/logout");
	}

	
	function handleRoomMessage(OutboundRoomMessage message, PlayerInfo currentPlayerInfo) {
		
		if (!message.success) {
			logout();
			return true;
		}
		
		if (is PlayerListMessage message) {
			if (message.isOldPlayer(currentPlayerInfo.id)) {
				logout();
				return true;
			} else {
				playerList.update(message);
				refreshPlayerList(playerList.findTable(currentPlayerInfo.id));
				// TODO show table
				return true;
			}
		} else if (is FoundEmptyTableMessage message) {
			if (exists tableId = message.tableId) {
				refreshPlayerList(tableId);
				return showTable(tableId, currentPlayerInfo);
			} else {
				return false;
			}
		} else if (is PlayerStateMessage message) {
			if (!message.hasGame) {
				logout();
				return true;
			} else {
				gui.showDialog("dialog-logout");
				return true;
			}
		} else {
			return false;
		}
	}
	
	function handleTableMessage(OutboundTableMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			gui.showQueueSize(queueSize = message.queueSize);
			// TODO some changes may occur on the state between the response and the registration
			gameEventClient?.close();
			gameEventClient = EventBusClient("OutboundGameMessage-``currentMatch.id``", onServerMessage, onServerError);
		} else if (is CreatedMatchMessage message) {
			gameEventClient?.close();
			gameEventClient = EventBusClient("OutboundGameMessage-``message.matchId``", onServerMessage, onServerError);
			if (exists playerInfo = extractPlayerInfo(), message.player1.id == playerInfo.id || message.player2.id == playerInfo.id) {
				// TODO store message
				gui.showDialog("dialog-accept");
			}
		}
		
		if (is JoinedTableMessage message) {
			gui.showQueueSize(++queueSize);
		} else if (is LeftTableMessage message) {
			gui.showQueueSize(--queueSize);
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleTableMessage(message);
		} else {
			return false;
		}
	}
	
	function handleMatchMessage(OutboundMatchMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is MatchEndedMessage message, exists eventBus = gameEventClient) {
			eventBus.close();
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleMatchMessage(message);
		} else {
			return false;
		}
	}
	
	function handleGameMessage(OutboundGameMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleGameMessage(message);
		} else {
			return false;
		}
	}
		
	shared actual Boolean handleServerMessage(String typeName, Object json)  {
		
		if (exists message = parseOutboundRoomMessage(typeName, json), exists currentPlayerInfo = extractPlayerInfo()) {
			return handleRoomMessage(message, currentPlayerInfo);
		} else if (exists message = parseOutboundTableMessage(typeName, json)) {
			return handleTableMessage(message);
		} else if (exists message = parseOutboundMatchMessage(typeName, json)) {
			return handleMatchMessage(message);
		} else if (exists message = parseOutboundGameMessage(typeName, json)) {
			return handleGameMessage(message);
		} else {
			onServerError("Unsupported message type: ``typeName``");
			return true;
		}
	}

	void roomCommander(InboundRoomMessage message) {
		switch(message)
		case (is RoomStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/listplayer");
		}
		case (is FindEmptyTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/opentable");
		}
		case (is EnterRoomMessage) {}
		case (is LeaveRoomMessage) {
			makeApiRequest("/api/room/``message.roomId``/leave");
		}
		case (is PlayerStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/player/``message.playerId``/state");
		}
		case (is FindMatchTableMessage) {}
	}

	void login(PlayerInfo currentPlayerInfo, RoomId currentRoomId) {
		print(currentPlayerInfo.toJson());
		roomEventClient = EventBusClient("OutboundRoomMessage-``currentRoomId``", onServerMessage, onServerError);
		roomCommander(RoomStateRequestMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
		gui.showBeginState(currentPlayerInfo);
	}
	
	shared void run() {
		if (exists currentRoomId = extractRoomId(), exists currentPlayerInfo = extractPlayerInfo()) {
			login(currentPlayerInfo, currentRoomId);
		} else {
			logout();
		}
	}
}