import backgammon.client {
	BasePage,
	EventBusClient
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
	PlayerInfo
}

import ceylon.json {
	Object,
	JsonArray=Array
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
	
	shared Boolean onButton(HTMLElement target) {
		if (target.id == "play") {
			if (exists roomId = extractRoomId(window.location.href)) {
				window.location.\iassign("``roomId``/play");
			}
		}
		return true;
	}
	
	shared Boolean onPlayerClick(String playerId) {
		print(playerId);
		return true;
	}
	
	shared void showPlayers(PlayerInfo[] newPlayers) {
		// TODO should be an array of ActivePlayerInfo
		value data = if (newPlayers.empty) then "{}" else JsonArray({for (p in newPlayers) Object({"playerId" -> p.id, "playerName" -> p.name, "playerScore" -> 0})}).string;
		value template = if (newPlayers.empty) then "#player-empty-template" else "#player-row-template";
		print(data);
		dynamic {
			jQuery("#player-list-table tbody").loadTemplate(jQuery(template), JSON.parse(data));
		}
	}
	
	shared Boolean handleRoomMessage(OutboundRoomMessage message) {
		if (is PlayerListMessage message) {
			showPlayers(message.newPlayers);
			return true;
		} else {
			return false;
		}
	}
		
	shared actual Boolean handleServerMessage(String typeName, Object json)  {
		if (exists message = parseOutboundRoomMessage(typeName, json)) {
			return handleRoomMessage(message);
		} else {
			return false;
		}
	}

	shared void run() {
		if (exists roomId = extractRoomId(window.location.href), exists playerInfo = extractPlayerInfo(window.document.cookie)) {
			print(playerInfo.toJson());
			roomEventClient = EventBusClient("OutboundRoomMessage-``roomId``", onServerMessage, onServerError);
			makeApiRequest("/api/room/``roomId``/playerlist");
		}
	}
}