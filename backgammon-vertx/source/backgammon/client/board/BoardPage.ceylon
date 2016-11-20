import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.browser {
	HTMLElement,
	window
}
import backgammon.shared {
	RoomResponseMessage,
	LeaveTableMessage,
	EndMatchMessage,
	formatRoomMessage,
	parseOutboundTableMessage,
	InboundGameMessage,
	MakeMoveMessage,
	parseOutboundMatchMessage,
	OutboundGameMessage,
	PlayerBeginMessage,
	GameStateRequestMessage,
	TableId,
	InboundMatchMessage,
	parseOutboundGameMessage,
	OutboundMatchMessage,
	MatchEndedMessage,
	InboundTableMessage,
	TableStateRequestMessage,
	UndoMovesMessage,
	OutboundTableMessage,
	StartGameMessage,
	EndGameMessage,
	CreatedMatchMessage,
	AcceptMatchMessage,
	TableStateResponseMessage,
	EndTurnMessage,
	PlayerId,
	JoinTableMessage
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
shared class BoardPage() extends BasePage() {
	value gui = BoardGui(window.document);
	variable TableClient? tableClient = null;
	variable String? draggedElementStyle = null;
	variable EventBusClient? tableEventClient = null;
	variable EventBusClient? gameEventClient = null;
	
	shared Boolean onStartDrag(HTMLElement source) {
		draggedElementStyle = source.getAttribute("style");
		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleStartDrag(source);
		} else {
			return false;
		}
	}
	
	shared Boolean onEndDrag(HTMLElement source) {
		// restore style
		if (exists style = draggedElementStyle) {
			source.setAttribute("style", style);
		}
		gui.hidePossibleMoves();
		return true;
	}
	
	shared Boolean onDrop(HTMLElement target, HTMLElement source) {
		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleDrop(target, source);
		} else {
			return false;
		}
	}
	
	shared Boolean onButton(HTMLElement target) {
		
		if (target.id == gui.leaveButtonId) {
			gui.showDialog("dialog-leave");
			return true;
		} else if (target.id == gui.submitButtonId, exists currentTableClient = tableClient) {
			return currentTableClient.handleSubmitEvent();
		} else if (target.id == gui.undoButtonId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleUndoEvent();
		}
		
		
		return false;
	}
	
	shared Boolean onChecker(HTMLElement checker) {
		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleCheckerSelection(checker);
		} else {
			return false;
		}
	}
	
	shared Boolean onTimer() {
		if (exists currentClient = tableClient) {
			return currentClient.handleTimerEvent(now());
		} else {
			return false;
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
	
	shared Boolean onPlayAgain() {
		window.location.\iassign("/start");
		return true;
	}
	
	shared actual Boolean handleServerMessage(String typeName, Object json) {
		if (exists message = parseOutboundTableMessage(typeName, json)) {
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
	
	TableId? extractTableId(String pageUrl) {
		value match = regex("/room/(\\w+)/table/(\\d+)").find(pageUrl);
		if (exists match, exists roomId = match.groups[0], exists table = match.groups[1]) {
			if (exists tableIndex = parseInteger(table)) {
				return TableId(roomId, tableIndex);
			} 
		}
		return null;
	}

	void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
		print(formatRoomMessage(message));
		switch (message)
		case (is AcceptMatchMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/accept");
		}
		case (is StartGameMessage) {
			// ignore
		}
		case (is EndMatchMessage) {
			// ignore
		}
		case (is PlayerBeginMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/begin");
		}
		case (is MakeMoveMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/move/``message.sourcePosition``/``message.targetPosition``");
		}
		case (is UndoMovesMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/undomoves");
		}
		case (is EndTurnMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/endturn");
		}
		case (is EndGameMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/endgame");
		}
		case (is GameStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/state");
		}
		case (is JoinTableMessage) {
			// ignore
		}
		case (is LeaveTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/leave");
		}
		case (is TableStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/state");
		}
	}
	
	shared void run() {
		if (exists tableId = extractTableId(window.location.href), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
			print(playerInfo.toJson());
			tableClient = TableClient(tableId, playerInfo, gui, gameCommander);
			tableEventClient = EventBusClient("OutboundTableMessage-``tableId``", onServerMessage, onServerError);
			gameCommander(TableStateRequestMessage(PlayerId(playerInfo.id), tableId));
		} else {
			gui.showInitialState();
		}
	}
}