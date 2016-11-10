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
	PlayerListMessage
}

import ceylon.json {
	Object
}
import ceylon.regex {
	regex
}
import backgammon.client.board {

	BoardGui
}
shared class RoomPage() extends BasePage() {
	
	value gui = BoardGui(window.document);
	variable EventBusClient? roomEventClient = null;
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
	
	shared Boolean onPlayerClick(String playerId) {
		// TODO
		print(playerId);
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
	
	shared Boolean handleRoomMessage(OutboundRoomMessage message) {
		if (is PlayerListMessage message) {
			showPlayers(message);
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
			gui.showEmptyGame();
		} else {
			gui.addClass("play", "hidden");
			gui.showEmptyGame();
		}
	}
}