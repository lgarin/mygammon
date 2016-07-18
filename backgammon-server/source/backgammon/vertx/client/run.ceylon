import backgammon.client {
	GameGui
}
import backgammon.common {
	TableId,
	parseRoomMessage,
	parsePlayerInfo,
	PlayerInfo,
	parseBase64PlayerInfo
}
import backgammon.game {
	white,
	black
}

import ceylon.interop.browser {
	window
}
import ceylon.interop.browser.dom {
	HTMLElement
}
import ceylon.json {
	parse,
	Object
}
import ceylon.regex {
	regex
}

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

void onServerMessage(dynamic eventBus, String messageString) {
	print(messageString);
	value json = parse(messageString);
	if (is Object json, exists typeName = json.keys.first) {
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

void registerMessageHandler(dynamic eventBus, String address) {
	dynamic {
		eventBus.onopen = void() {
			eventBus.registerHandler(address, (dynamic error, dynamic message) {
				onServerMessage(eventBus, JSON.stringify(message));
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

"Run the module `backgammon.vertx.client`."
shared void run() {
	
	print(extractPlayerInfo(window.document.cookie));
	
	gui.redrawCheckers(black, [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10]);
	gui.redrawCheckers(white, [10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]);

	if (exists tableId = extractTableId(window.location.string)) {
	    dynamic {
			dynamic eb = EventBus("/eventbus/");
			registerMessageHandler(eb, "OutboundTableMessage-``tableId``");
	    }
	}
    /*
    value request = newXMLHttpRequest();
    request.open("GET", "/api/player/gamestate", true);
    request.send();
    request.onload = void (Event event) {
      print(request.responseText);  
    };
     */
}