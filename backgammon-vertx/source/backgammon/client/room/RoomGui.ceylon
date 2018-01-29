import backgammon.client.board {
	BoardGui
}
import backgammon.client.browser {
	Document
}
import backgammon.shared {
	PlayerState
}

import ceylon.json {
	JsonArray
}
shared class RoomGui(Document document) extends BoardGui(document) {
	
	shared String playButtonId = "play";
	shared String newButtonId = "new";
	
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
	
	shared void showPlayerList(JsonArray data) {
		dynamic {
			jQuery("#player-list").dataTable().api().destroy();
			jQuery("#player-list tbody").loadTemplate(jQuery("#player-row-template"), JSON.parse(data.string));
			jQuery("#player-list").dataTable().api().rows().invalidate("dom").draw();
		}
	}
	
	shared void showEmptyPlayerList() {
		dynamic {
			jQuery("#player-list tbody").loadTemplate(jQuery("#player-empty-template"));
		}
	}

	shared actual void showBeginState(PlayerState playerState) {
		super.showBeginState(playerState);
		showPlayButton();
		hideTablePreview();
	}
}