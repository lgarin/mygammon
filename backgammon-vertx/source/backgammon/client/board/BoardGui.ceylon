import backgammon.client {
	TableGui
}
import backgammon.client.browser {
	Document
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
	
}