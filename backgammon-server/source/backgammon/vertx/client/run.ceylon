import backgammon.client {
	GameGui
}
import backgammon.common {
	TableId,
	parseRoomMessage,
	parsePlayerInfo,
	PlayerInfo,
	parseBase64PlayerInfo,
	GameEndedMessage
}
import backgammon.game {
	white,
	black
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

variable PlayerInfo? playerInfo = null; 
GameGui gui = GameGui(window.document);

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
	gui.disableUndoButton();
	return true;
}

shared Boolean onChecker(HTMLElement target) {
	gui.deselectAllCheckers();
	gui.showSelectedChecker(target);
	return true;
}

void onServerMessage(String messageString) {
	print(messageString);
	value json = parse(messageString);
	if (is Object json, exists typeName = json.keys.first) {
		print(typeName);
		value message = parseRoomMessage(typeName, json.getObject(typeName));
		print(message);
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
	dynamic {
		dynamic eventBus = EventBus("/eventbus/");
		eventBus.onopen = void() {
			eventBus.registerHandler(address, (dynamic error, dynamic message) {
				onServerMessage(JSON.stringify(message));
			});
		};
	}
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
		}  
	};
}

void requestTableState(TableId tableId) {
	makeApiRequest("/api/room/``tableId.roomId``/table/``tableId.table``/state");
}

"Run the module `backgammon.vertx.client`."
shared void run() {
	
	playerInfo = extractPlayerInfo(window.document.cookie);
	
	gui.redrawCheckers(black, [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10]);
	gui.redrawCheckers(white, [10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]);

	if (exists tableId = extractTableId(window.location.string)) {
		registerMessageHandler("OutboundTableMessage-``tableId``");
		requestTableState(tableId);
	}
}