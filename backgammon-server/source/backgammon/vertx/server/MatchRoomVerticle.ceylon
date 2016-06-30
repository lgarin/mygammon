import backgammon.server.common {
	RoomConfiguration
}
import backgammon.server.match {
	MatchRoom
}

import ceylon.time {
	Duration,
	now
}

import io.vertx.ceylon.core {
	Verticle
}
import ceylon.json {

	Object
}
import io.vertx.ceylon.core.eventbus {

	Message
}
import backgammon.common {

	OutboundTableMessage,
	OutboundMatchMessage
}
class GameRoomVerticle() extends Verticle() {
	
	shared actual void start() {

		value eb = vertx.eventBus();
		value config = RoomConfiguration("Room1", 100, Duration(60000), Duration(30000));
		void handler(OutboundTableMessage|OutboundMatchMessage msg) {
			eb.send(config.roomName, msg.string);
		}
		
		value room = MatchRoom(config, handler);
		
		/*
		eb.consumer(config.roomName, void (Message<Object> msg) {
			if (exists token = msg.headers().get("jwt")) {
				room.processMessage(msg, now());
			}
		});
		 */
	}
}