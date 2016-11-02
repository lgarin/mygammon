import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.browser {
	window
}
import backgammon.shared {
	RoomId
}

import ceylon.json {
	Object
}
import ceylon.regex {
	regex
}
shared class RoomPage() extends BasePage() {
	
	variable EventBusClient? roomEventClient = null;
	
	RoomId? extractRoomId(String pageUrl) {
		value match = regex("/room/(\\w+)").find(pageUrl);
		if (exists match, exists roomId = match.groups[0]) {
			return RoomId(roomId);
		}
		return null;
	}
	
	shared actual Boolean handleServerMessage(String typeName, Object json)  {
		return false;
	}

	shared void run() {
		if (exists tableId = extractRoomId(window.location.href), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
			print(playerInfo.toJson());
			roomEventClient = EventBusClient("OutboundRoomMessage-``tableId``", onServerMessage, onServerError);
		} else {
			
		}
	}
}