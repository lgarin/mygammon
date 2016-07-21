import backgammon.client {
	GameGui
}
import backgammon.common {
	TableId,
	PlayerInfo,
	parseBase64PlayerInfo,
	RoomMessage,
	TableStateResponseMessage,
	RoomResponseMessage,
	parseOutboundRoomMessage
}
import backgammon.game {
	player1Color,
	player2Color
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

variable PlayerInfo? playerInfo = null; 
GameGui gui = GameGui(window.document);
EventBusClient eventBus = EventBusClient();

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
	
	print("button:``target.id``");
	if (target.id == gui.leaveButtonId) {
		window.location.\iassign("/start");
	}
	return true;
}

shared Boolean onChecker(HTMLElement target) {
	gui.deselectAllCheckers();
	gui.showSelectedChecker(target);
	return true;
}

shared Boolean onTimer() {
	print(now());
	return true;
}

void handleTableStateResponseMessage(TableStateResponseMessage message) {
	if (exists match = message.match) {
		gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
		gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
		if (match.gameStarted) {
			gui.showPlayerMessage(player1Color, "Loading...", true);
			gui.showPlayerMessage(player2Color, "Loading...", true);
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.showLeaveButton(null);
			// TODO fetch game state
		} else if (match.gameEnded) {
			if (exists winnerId = match.winnerId, winnerId == match.player1.id) {
				gui.showPlayerMessage(player1Color, "Winner", false);
				gui.showPlayerMessage(player2Color, "", false);
			} else if (exists winnerId = match.winnerId, winnerId == match.player2.id) {
				gui.showPlayerMessage(player1Color, "", false);
				gui.showPlayerMessage(player2Color, "Winner", false);
			} else {
				gui.showPlayerMessage(player1Color, "Tie", false);
				gui.showPlayerMessage(player2Color, "Tie", false);
			}
			gui.hideSubmitButton();
			gui.hideUndoButton();
			gui.showLeaveButton(null);
		} else {
			if (match.player1Ready) {
				gui.showPlayerMessage(player1Color, "Ready", false);
			} else {
				gui.showPlayerMessage(player1Color, "Play?", true);
			}
			if (match.player2Ready) {
				gui.showPlayerMessage(player2Color, "Ready", false);
			} else {
				gui.showPlayerMessage(player2Color, "Play?", true);
			}
			
			if (exists currentPlayer = playerInfo) {
				if (currentPlayer.id == match.player1.id && !match.player1Ready) {
					gui.showSubmitButton("Start");
				} else if (currentPlayer.id == match.player2.id && !match.player2Ready) {
					gui.showSubmitButton("Start");
				} else {
					gui.hideSubmitButton();
				}
			} else {
				gui.hideSubmitButton();
			}
			
			gui.hideUndoButton();
			gui.showLeaveButton(null);
		}
	} else if (exists currentPlayer = playerInfo) {
		gui.showPlayerInfo(player1Color, currentPlayer.name, currentPlayer.pictureUrl);
		gui.showPlayerMessage(player1Color, "Joined", false);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	} else {
		gui.showPlayerInfo(player1Color, null, null);
		gui.showPlayerMessage(player1Color, "Waiting...", true);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
}

void handleRoomMessage(RoomMessage message) {
	if (is RoomResponseMessage message, !message.success) {
		window.location.reload();
		return;
	}
	switch (message)
	case (is TableStateResponseMessage) {
		handleTableStateResponseMessage(message);
	}
	else {
		onServerError("Unsupported message response: ``message.toJson()``");
	}
}

void onServerMessage(String messageString) {
	if (is Object json = parse(messageString), exists typeName = json.keys.first) {
		print(typeName);
		if (exists message = parseOutboundRoomMessage(typeName, json.getObject(typeName))) {
			handleRoomMessage(message);
		} else {
			onServerError("Cannot parse server response: ``messageString``");
		}
	} else {
		onServerError("Cannot parse server response: ``messageString``");
	}
}

void onServerError(String messageString) {
	dynamic {
		alert(messageString);
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

void registerMessageHandler(String address) {
	eventBus.registerHandler(void (String? message, String? error) {
		if (exists message) {
			onServerMessage(message);
		} else if (exists error) {
			onServerError(error);
		}
	});
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
			onServerError(request.responseText);
		}
	};
}

void requestTableState(TableId tableId) {
	makeApiRequest("/api/room/``tableId.roomId``/table/``tableId.table``/state");
}

"Run the module `backgammon.vertx.client`."
shared void run() {
	
	playerInfo = extractPlayerInfo(window.document.cookie);

	gui.showInitialState();
	
	if (exists tableId = extractTableId(window.location.string)) {
		registerMessageHandler("OutboundTableMessage-``tableId``");
		requestTableState(tableId);
	}
}