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
	LeftRoomMessage,
	PlayerStateRequestMessage,
	PlayerStateMessage
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
	
	value gui = RoomGui(window.document);
	variable TableClient? tableClient = null;
	variable EventBusClient? roomEventClient = null;
	variable EventBusClient? tableEventClient = null;
	variable EventBusClient? gameEventClient = null;
	value playerList = PlayerListModel();
	
	variable Integer queueSize = 0;
	variable PlayerInfo? playerInfo = null;
	variable RoomId? roomId = null;
	
	RoomId? extractRoomId(String pageUrl) {
		value match = regex("/room/(\\w+)").find(pageUrl);
		if (exists match, exists roomId = match.groups[0]) {
			return RoomId(roomId);
		}
		return null;
	}
	
	shared Boolean onButton(HTMLElement target) {
		if (target.id == gui.playButtonId) {
			if (exists currentRoomId = roomId) {
				window.location.\iassign("``currentRoomId``/play");
				return true;
			} else {
				return false;
			}
		} else if (target.id == gui.newButtonId) {
			if (exists currentRoomId = roomId, exists currentPlayerInfo = playerInfo) {
				roomCommander(FindEmptyTableMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
				return true;
			} else {
				return false;
			}
		} else if (target.id == gui.sitButtonId) {
			if (exists currentRoomId = roomId, exists currentPlayerInfo = playerInfo, exists tableId = tableClient?.tableId) {
				gameCommander(JoinTableMessage(PlayerId(currentPlayerInfo.id), tableId));
				return true;
			} else {
				return false;
			}
		} else if (target.id == gui.startButtonId) {
			window.location.\iassign("/start");
			return true;
		} else if (target.id == gui.exitButtonId) {
			if (exists currentRoomId = roomId, exists currentPlayerInfo = playerInfo) {
				roomCommander(PlayerStateRequestMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
				return true;
			} else {
				//gui.showClosedState();
				window.location.\iassign("/logout");
				return true;
			}
		} else {
			return false;
		}
	}
	
	void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
		print(formatRoomMessage(message));
		switch (message)
		case (is AcceptMatchMessage) {
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
		gui.showInitialGame();
		tableClient = TableClient(newTableId, playerInfo, gui, gameCommander);
		tableEventClient = EventBusClient("OutboundTableMessage-``newTableId``", onServerMessage, onServerError);
		gameCommander(TableStateRequestMessage(PlayerId(playerInfo.id), newTableId));
		gui.showTablePreview();
		gui.showSitButton();
		gui.showQueueSize(null);
		return true;
	}
	
	shared Boolean onLogoutConfirmed() {
		window.location.\iassign("/logout");
		return true;
	}
	
	shared Boolean onPlayerClick(String playerId) {
		
		if (exists currentGameEventClient = gameEventClient) {
			currentGameEventClient.close();
		}
		
		if (exists currentTableEventClient = tableEventClient) {
			currentTableEventClient.close();
		}
		
		if (exists tableId = playerList.findTable(playerId), exists currentPlayerInfo = playerInfo) {
			return showTable(tableId, currentPlayerInfo);
		} else {
			gui.hideTablePreview();
			return true;
		}
	}
	
	shared void showPlayers(PlayerListMessage message) {
		playerList.update(message);
		if (playerList.empty) {
			gui.showEmptyPlayerList();
		} else {
			gui.showPlayerList(playerList.toTemplateData());
		}
	}
	
	shared Boolean onTimer() {
		if (exists currentClient = tableClient) {
			return currentClient.handleTimerEvent(now());
		} else {
			return false;
		}
	}
	
	Boolean handleRoomMessage(OutboundRoomMessage message) {
		
		if (!message.success && message is PlayerListMessage) {
			gui.showClosedState();
			return true;
		} else if (!message.success && message is PlayerStateMessage) {
			gui.showClosedState();
			return true;
		} else if (!message.success) {
			return false;
		}
		
		if (is PlayerListMessage message) {
			showPlayers(message);
			return true;
		} else if (is FoundEmptyTableMessage message) {
			if (exists tableId = message.tableId, exists currentPlayerInfo = playerInfo) {
				return showTable(tableId, currentPlayerInfo);
			} else {
				return false;
			}
		} else if (is LeftRoomMessage message) {
			
			if (exists currentGameEventClient = gameEventClient) {
				currentGameEventClient.close();
			}
			if (exists currentTableEventClient = tableEventClient) {
				currentTableEventClient.close();
			}
			gui.showClosedState();
			return true;
		} else if (is PlayerStateMessage message) {
			if (!message.hasGame) {
				window.location.\iassign("/logout");
				return true;
			} else {
				gui.showDialog("dialog-logout");
				return true;
			}
		} else {
			return false;
		}
	}
	
	Boolean handleTableMessage(OutboundTableMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			gui.showQueueSize(queueSize = message.queueSize);
			// TODO some changes may occur on the state between the response and the registration
			gameEventClient = EventBusClient("OutboundGameMessage-``currentMatch.id``", onServerMessage, onServerError);
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
	
	Boolean handleMatchMessage(OutboundMatchMessage message) {
		
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
	
	Boolean handleGameMessage(OutboundGameMessage message) {
		
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
		if (exists message = parseOutboundRoomMessage(typeName, json)) {
			return handleRoomMessage(message);
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

	shared void run() {
		roomId = extractRoomId(window.location.href);
		playerInfo = extractPlayerInfo(window.document.cookie);
		if (exists currentRoomId = roomId, exists currentPlayerInfo = playerInfo) {
			print(currentPlayerInfo.toJson());
			roomEventClient = EventBusClient("OutboundRoomMessage-``currentRoomId``", onServerMessage, onServerError);
			roomCommander(RoomStateRequestMessage(PlayerId(currentPlayerInfo.id), currentRoomId));
			gui.showBeginState(currentPlayerInfo);
		} else {
			gui.showClosedState();
		}
	}
}