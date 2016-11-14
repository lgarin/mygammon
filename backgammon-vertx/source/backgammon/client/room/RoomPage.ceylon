import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.board {
	BoardGui,
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
	CreatedMatchMessage,
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
	FindMatchTableMessage
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
	
	value gui = BoardGui(window.document);
	variable TableClient? tableClient = null;
	variable EventBusClient? roomEventClient = null;
	variable EventBusClient? tableEventClient = null;
	variable EventBusClient? gameEventClient = null;
	value playerList = PlayerListModel();
	
	RoomId? extractRoomId(String pageUrl) {
		value match = regex("/room/(\\w+)").find(pageUrl);
		if (exists match, exists roomId = match.groups[0]) {
			return RoomId(roomId);
		}
		return null;
	}
	
	shared Boolean onButton(HTMLElement target) {
		if (target.id == "play") {
			if (exists roomId = extractRoomId(window.location.href)) {
				window.location.\iassign("``roomId``/play");
			}
		}
		return true;
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
	}
	
	shared Boolean onPlayerClick(String playerId) {
		
		if (exists currentTableEventClient = tableEventClient) {
			currentTableEventClient.close();
		}
		
		if (exists tableId = playerList.findTable(playerId), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
			tableClient = TableClient(tableId, playerInfo, gui, gameCommander);
			tableEventClient = EventBusClient("OutboundTableMessage-``tableId``", onServerMessage, onServerError);
			gameCommander(TableStateRequestMessage(PlayerId(playerInfo.id), tableId));
		} else {
			gui.showInitialState();
		}
		
		return true;
	}
	
	shared void showPlayers(PlayerListMessage message) {
		playerList.update(message);
		value data = playerList.toTemplateData();
		value template = if (playerList.empty) then "#player-empty-template" else "#player-row-template";
		dynamic {
			jQuery("#player-list-table tbody").loadTemplate(jQuery(template), JSON.parse(data));
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
		if (is PlayerListMessage message) {
			showPlayers(message);
			return true;
		} else {
			return false;
		}
	}
	
	Boolean handleTableMessage(OutboundTableMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			// TODO some changes may occur on the state between the response and the registration
			gameEventClient = EventBusClient("OutboundGameMessage-``currentMatch.id``", onServerMessage, onServerError);
		} else if (is CreatedMatchMessage message) {
			gameEventClient = EventBusClient("OutboundGameMessage-``message.matchId``", onServerMessage, onServerError);
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
			makeApiRequest("/api/room/``message.roomId``/playerlist");
		}
		case (is EnterRoomMessage) {}
		case (is LeaveRoomMessage) {}
		case (is FindMatchTableMessage) {}
	}

	shared void run() {
		if (exists roomId = extractRoomId(window.location.href), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
			print(playerInfo.toJson());
			roomEventClient = EventBusClient("OutboundRoomMessage-``roomId``", onServerMessage, onServerError);
			roomCommander(RoomStateRequestMessage(PlayerId(playerInfo.id), roomId));
			gui.showEmptyGame();
		} else {
			gui.addClass("play", "hidden");
			gui.showEmptyGame();
		}
	}
}