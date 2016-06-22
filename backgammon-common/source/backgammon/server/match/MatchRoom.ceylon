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
	
	value room = Room(configuration.roomName, configuration.tableCount, configuration.maxMatchJoinTime, messageBroadcaster);
	
	shared Boolean processMessage(InboundPlayerMessage message, Instant currentTime) {
		// TODO implement flooding control
		
		if (is EnterRoomMessage message) {
			
		}
		
		return false;
	}

	shared void removeInactivePlayers(Instant currentTime) {
		
	}
}