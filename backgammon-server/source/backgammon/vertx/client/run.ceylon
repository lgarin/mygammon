import ceylon.json { Object, parse }
import ceylon.interop.browser { window }
import ceylon.interop.browser.dom {

	EventTarget,
	EventListener,
	Event,
	Node,
	Element,
	HTMLElement,
	HTMLCollection
}
import backgammon.client {

	GameGui
}
import backgammon.game {

	white,
	black
}

GameGui gui = GameGui(window.document);

shared Boolean onStartDrag(HTMLElement source) {
	
		print("start:``source.parentElement?.id else ""``");
	
	return true;
}

shared Boolean onEndDrag(HTMLElement source) {
	
	print("end:``source.parentElement?.id else ""``");
	
	return true;
}

shared Boolean onDrop(HTMLElement target, HTMLElement source) {
	
	print("drop target:``target.id``");
	print("drop source:``source.parentElement?.id else ""``");
	
	return true;
}

shared Boolean onButton(HTMLElement target) {
	
	print("button:``target.id``");
	gui.disableUndoButton();
	return true;
}

shared Boolean onChecker(HTMLElement target) {
	
	print("checker:``target.parentElement?.id else ""``");
	
	return true;
}

"Run the module `backgammon.vertx.client`."
shared void run() {

	void onMessage(String messageString) {
		value message = parse(messageString);
		print(message);
	}

	
	value location = window.location.string;
	print(location);
	
	gui.redrawCheckers(black, [1,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,1]);
	gui.redrawCheckers(white, [15]);

    dynamic {
        dynamic eb = EventBus("/eventbus/");
        eb.onopen = void() {
            eb.registerHandler("msg.to.client", (dynamic error, dynamic message) {
               onMessage(JSON.stringify(message));
            });
        };
    }
}