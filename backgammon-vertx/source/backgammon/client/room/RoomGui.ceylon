import backgammon.client.board {
	BoardGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {

	PlayerInfo
}
class RoomGui(Document document) extends BoardGui(document) {
	
	shared String playButtonId = "play";
	shared String newButtonId = "new";
	shared String sitButtonId = "sit";
	
	value tablePreviewId = "table-preview";
	
	shared void hidePlayButton() {
		addClass(playButtonId, "hidden");
	}
	
	shared void showPlayButton() {
		removeClass(playButtonId, "hidden");
	}
	
	shared void hideNewButton() {
		addClass(newButtonId, "hidden");
	}
	
	shared void showNewButton() {
		removeClass(newButtonId, "hidden");
	}
	
	shared void hideSitButton() {
		addClass(sitButtonId, "hidden");
	}
	
	shared void showSitButton() {
		removeClass(sitButtonId, "hidden");
	}
	
	shared void hideTablePreview() {
		addClass(tablePreviewId, "hidden");
	}
	
	shared void showTablePreview() {
		removeClass(tablePreviewId, "hidden");
	}
	
	shared void showQueueSize(Integer? queueSize) {
		replaceVariables({"queue-size" -> (queueSize?.string else "-")});
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
		hideSitButton();
		hideTablePreview();
	}
}