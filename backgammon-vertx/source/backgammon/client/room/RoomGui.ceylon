import backgammon.client.board {
	BoardGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {

	PlayerInfo,
	TableId,
	PlayerState
}
import ceylon.json {

	Object
}
class RoomGui(Document document) extends BoardGui(document) {
	
	shared String playButtonId = "play";
	shared String newButtonId = "new";
	shared String joinButtonId = "join";
	
	value tablePreviewId = "table-preview";
	
	shared void hidePlayButton() {
		addClass(playButtonId, hiddenClass);
	}
	
	shared void showPlayButton() {
		removeClass(playButtonId, hiddenClass);
	}
	
	shared void hideNewButton() {
		addClass(newButtonId, hiddenClass);
	}
	
	shared void showNewButton() {
		removeClass(newButtonId, hiddenClass);
	}

	shared void hideTablePreview() {
		addClass(tablePreviewId, hiddenClass);
	}
	
	shared void showTablePreview() {
		removeClass(tablePreviewId, hiddenClass);
	}
	
	shared void hideJoinButton() {
		addClass(joinButtonId, hiddenClass);
	}
	
	shared void showTableInfo(TableId tableId, PlayerState? playerState) {
		value baseTableLink = "/room/``tableId.roomId``/table/``tableId.table``"; 
		value sitted = playerState?.isAtTable(tableId) else false;
		value tableLink =  if (sitted) then "``baseTableLink``/play" else "``baseTableLink``/view";
		value buttonClass = if (sitted) then hiddenClass else "";
		value data = Object {"tableLink" -> tableLink, "tableId" -> tableId.table, "buttonClass" -> buttonClass}.string;
		dynamic {
			jQuery("#table-info").loadTemplate(jQuery("#table-info-template"), JSON.parse(data));
		}
	}
	
	shared void showPlayerList(String data) {
		dynamic {
			jQuery("#player-list tbody").loadTemplate(jQuery("#player-row-template"), JSON.parse(data));
		}
	}
	
	shared void showEmptyPlayerList() {
		dynamic {
			jQuery("#player-list tbody").loadTemplate(jQuery("#player-empty-template"));
		}
	}

	shared actual void showBeginState(PlayerInfo playerInfo) {
		super.showBeginState(playerInfo);
		showPlayButton();
		hideTablePreview();
	}
}