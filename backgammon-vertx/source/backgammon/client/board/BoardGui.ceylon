import backgammon.client {
	TableGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {
	PlayerState,
	TableId
}

import ceylon.json {
	JsonObject
}

shared class BoardGui(Document document) extends TableGui(document) {
	
	shared String leaveButtonId = "leave";
	shared String joinButtonId = "join";
	shared String homeButtonId = "home";
	
	shared void hideLeaveButton() {
		addClass(leaveButtonId, hiddenClass);
	}
	
	shared void showLeaveButton() {
		removeClass(leaveButtonId, hiddenClass);
	}
	
	shared void showJoinButton() {
		removeClass(joinButtonId, hiddenClass);
	}
	
	shared void hideJoinButton() {
		addClass(joinButtonId, hiddenClass);
	}
	
	shared void hideHomeButton() {
		addClass(homeButtonId, hiddenClass);
	}
	
	shared void showHomeButton() {
		removeClass(homeButtonId, hiddenClass);
	}

	shared void showTableInfo(TableId tableId, PlayerState? currentPlayerState) {
		value baseTableLink = "/room/``tableId.roomId``/table?id=``tableId.table``"; 
		value sitted = currentPlayerState?.isAtTable(tableId) else false;
		value buttonClass = if (sitted) then hiddenClass else "";
		value playing = currentPlayerState?.isPlayingAtTable(tableId) else false;
		value tableLink =  if (playing) then "``baseTableLink``&action=play" else "``baseTableLink``&action=view";
		
		value data = JsonObject {"tableLink" -> tableLink, "tableId" -> tableId.table, "joinButtonClass" -> buttonClass}.string;
		dynamic {
			jQuery("#table-info").loadTemplate(jQuery("#table-info-template"), JSON.parse(data));
		}
	}
}