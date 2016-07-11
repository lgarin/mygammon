import backgammon.client {
	GameGui
}
import backgammon.game {
	white,
	black
}

import ceylon.interop.browser {
	window
}
import ceylon.interop.browser.dom {
	HTMLElement
}
import ceylon.json {
	parse
}

GameGui gui = GameGui(window.document);

shared Boolean onStartDrag(HTMLElement source) {
	gui.deselectAllCheckers();
	gui.showSelectedChecker(source);
	print(gui.getPosition(source));
	//TODO show possible moves?
	return true;
}

shared Boolean onEndDrag(HTMLElement source) {
	gui.deselectAllCheckers();
	gui.hidePossibleMoves();
	return true;
}

shared Boolean onDrop(HTMLElement target, HTMLElement source) {
	print(gui.getPosition(source));
	print(gui.getPosition(target));
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
	gui.deselectAllCheckers();
	gui.showSelectedChecker(target);
	return true;
}

void onServerMessage(String messageString) {
	value message = parse(messageString);
	print(message);
}

"Run the module `backgammon.vertx.client`."
shared void run() {

	value location = window.location.string;
	print(location);
	
	gui.redrawCheckers(black, [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10]);
	gui.redrawCheckers(white, [10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]);

    dynamic {
        dynamic eb = EventBus("/eventbus/");
        eb.onopen = void() {
            eb.registerHandler("msg.to.client", (dynamic error, dynamic message) {
                onServerMessage(JSON.stringify(message));
            });
        };
    }
}