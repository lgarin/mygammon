import backgammon.client.board {
	BoardGui
}
import backgammon.client.browser {
	Document
}
class RoomGui(Document document) extends BoardGui(document) {
	
	value playButtonId = "play";
	value tablePreviewId = "table-preview";
	
	shared void hidePlayButton() {
		addClass(playButtonId, "hidden");
	}
	
	shared void showPlayButton() {
		removeClass(playButtonId, "hidden");
	}
	
	shared void hideTablePreview() {
		addClass(tablePreviewId, "hidden");
	}
	
	shared void showTablePreview() {
		removeClass(tablePreviewId, "hidden");
	}
}