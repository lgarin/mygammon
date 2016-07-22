import backgammon.client {
	GameGui,
	TableClient
}
import backgammon.common {
	TableId,
	PlayerInfo,
	parseBase64PlayerInfo,
	RoomResponseMessage,
	parseOutboundRoomMessage,
	InboundGameMessage,
	CreatedMatchMessage,
	OutboundGameMessage,
	OutboundRoomMessage,
	parseOutboundTableMessage,
	parseOutboundMatchMessage,
	parseOutboundGameMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	InboundMatchMessage,
	AcceptMatchMessage,
	StartGameMessage,
	PlayerReadyMessage,
	CheckTimeoutMessage,
	MakeMoveMessage,
	UndoMovesMessage,
	EndTurnMessage,
	EndGameMessage,
	GameStateRequestMessage
}

import ceylon.interop.browser {
	window,
	newXMLHttpRequest
}
import ceylon.interop.browser.dom {
	HTMLElement,
	Event
}
import ceylon.json {
	parse,
	Object
}
import ceylon.regex {
	regex
}
import ceylon.time {
	now
}

GameGui gui = GameGui(window.document);
EventBusClient eventBus = EventBusClient();
variable TableClient? tableClient = null;

shared Boolean onStartDrag(HTMLElement source) {
	gui.deselectAllCheckers();
	gui.showSelectedChecker(source);
	print(gui.getPosition(source));
	//TODO show possible moves?
	return true;
}

shared Boolean onEndDrag(HTMLElement source) {
	gui.deselectAllCheckers();
	gui.hidePossibleMoves();
	return true;
}

shared Boolean onDrop(HTMLElement target, HTMLElement source) {
	print(gui.getPosition(source));
	print(gui.getPosition(target));
	print("drop target:``target.id``");
	print("drop source:``source.parentElement?.id else ""``");
	
	return true;
}

shared Boolean onButton(HTMLElement target) {
	
	if (target.id == gui.leaveButtonId) {
		if (window.confirm("Do you really want to leave the table?")) {
			window.location.\iassign("/start");
			return true;
		} else {
			return false;
		}
	} else if (target.id == gui.submitButtonId, exists currentTableClient = tableClient) {
		return currentTableClient.handleSubmitEvent();
	}
	return false;
}

shared Boolean onChecker(HTMLElement target) {
	gui.deselectAllCheckers();
	gui.showSelectedChecker(target);
	return true;
}

shared Boolean onTimer() {
	if (exists currentClient = tableClient) {
		return currentClient.handleTimerEvent(now());
	} else {
		return false;
	}
}

Boolean handleServerMessage(String typeName, Object json) {
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

void onServerMessage(String messageString) {
	print(messageString);
	if (is Object json = parse(messageString), exists typeName = json.keys.first) {
		if (!handleServerMessage(typeName, json.getObject(typeName))) {
			window.location.reload();
		}
	} else {
		onServerError("Cannot parse server response: ``messageString``");
	}
}

void onServerError(String messageString) {
	window.alert(messageString);
}

void registerMessageHandler(String address) {
	eventBus.registerHandler(address, void (String? message, String? error) {
		if (exists message) {
			onServerMessage(message);
		} else if (exists error) {
			onServerError(error);
		}
	});
}

Boolean handleRoomMessage(OutboundRoomMessage message) {
	if (!message.success) {
		return false;
	}
	
	if (exists currentClient = tableClient) {
		return currentClient.handleRoomMessage(message);
	} else {
		return false;
	}
}

Boolean handleTableMessage(OutboundTableMessage message) {

	if (is RoomResponseMessage message, !message.success) {
		return false;
	}

	if (is CreatedMatchMessage message) {
		registerMessageHandler("OutboundGameMessage-``message.matchId``");
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

TableId? extractTableId(String pageUrl) {
	value match = regex("/room/(\\w+)/table/(\\d+)").find(pageUrl);
	if (exists match, exists roomId = match.groups[0], exists table = match.groups[1]) {
		if (exists tableIndex = parseInteger(table)) {
			return TableId(roomId, tableIndex);
		} 
	}
	return null;
}

PlayerInfo? extractPlayerInfo(String cookie) {
	value match = regex("playerInfo=([^\\;\\s]+)").find(cookie);
	if (exists match, exists infoString = match.groups[0]) {
		return parseBase64PlayerInfo(infoString);
	}
	return null;
}

void makeApiRequest(String url) {
	value request = newXMLHttpRequest();
	request.open("GET", url, true);
	request.send();
	request.onload = void (Event event) {
		if (request.status == 200) {
			onServerMessage(request.responseText);
		} else {
			onServerError(request.statusText);
		}
	};
}

void requestTableState(TableId tableId) {
	makeApiRequest("/api/room/``tableId.roomId``/table/``tableId.table``/state");
}

void gameCommander(InboundGameMessage|InboundMatchMessage message) {
	// TODO implement other message
	switch (message)
	case (is AcceptMatchMessage) {
		makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/accept");
	}
	case (is StartGameMessage) {}
	case (is PlayerReadyMessage) {}
	case (is CheckTimeoutMessage) {}
	case (is MakeMoveMessage) {}
	case (is UndoMovesMessage) {}
	case (is EndTurnMessage) {}
	case (is EndGameMessage) {}
	case (is GameStateRequestMessage) {}
}

"Run the module `backgammon.vertx.client`."
shared void run() {
	gui.showInitialState();
	
	if (exists tableId = extractTableId(window.location.string), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
		tableClient = TableClient(tableId, playerInfo, gui, gameCommander);
		registerMessageHandler("OutboundTableMessage-``tableId``");
		requestTableState(tableId);
	}
}