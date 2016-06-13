import backgammon.common {
	PlayerId,
	InboundPlayerMessage,
	EnterRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage
}
import backgammon.server.common {
	RoomConfiguration
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	value room = Room(configuration.roomName, configuration.tableCount, messageBroadcaster);
	
	shared Boolean processMessage(InboundPlayerMessage message, Instant currentTime) {
		// TODO implement flooding control
		
		if (is EnterRoomMessage message) {
			
		}
		
		return false;
	}
	
	shared PlayerId createPlayer(String name) {
		return room.createPlayer(name).id;
	}
	
	
	
	shared void removeInactivePlayers(Instant currentTime) {
		
	}
}