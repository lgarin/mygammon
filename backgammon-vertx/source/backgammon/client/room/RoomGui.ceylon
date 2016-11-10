import backgammon.client {

	GameGui
}
import backgammon.client.browser {

	Document
}
class RoomGui(Document document) extends GameGui(document) {
	
	value playButtonId = "play";
	
	shared void hidePlayButton() {
		addClass(playButtonId, "hidden");
	}
	
	shared void showPlayButton() {
		removeClass(playButtonId, "hidden");
	}
}