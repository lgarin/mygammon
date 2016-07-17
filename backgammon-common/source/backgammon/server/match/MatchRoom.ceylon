import backgammon.common {
	InboundRoomMessage,
	EnterRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	LeaveRoomMessage,
	FindMatchTableMessage,
	EnteredRoomMessage,
	LeaftRoomMessage,
	FoundMatchTableMessage,
	OutboundRoomMessage
}
import backgammon.server.common {
	RoomConfiguration,
	ObtainableLock
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomName, configuration.tableCount, configuration.maxMatchJoinTime, messageBroadcaster);
	
	function process(InboundRoomMessage message) {
		switch (message)
		case (is EnterRoomMessage) {
			if (exists player = room.players[message.playerId]) {
				return EnteredRoomMessage(player.id, room.id, false);
			}
			value player = room.createPlayer(message.playerInfo);
			return EnteredRoomMessage(player.id, room.id, true);
		}
		case (is LeaveRoomMessage) {
			if (exists player = room.players[message.playerId], player.leaveRoom()) {
				return LeaftRoomMessage(player.id, room.id, true);
			}
			return LeaftRoomMessage(message.playerId, room.id, false);
		}
		case (is FindMatchTableMessage) {
			if (exists player = room.players[message.playerId], player.findMatchTable()) {
				return FoundMatchTableMessage(player.id, room.id, player.tableIndex);
			}
			return FoundMatchTableMessage(message.playerId, room.id, null);
		}
	}
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message, Instant currentTime) {
		// TODO implement flooding control
		try (lock) {
			return process(message);
		}
	}

	shared void removeInactivePlayers(Instant currentTime) {
		room.removeInactivePlayers(currentTime.plus(configuration.playerInactiveTimeout));
	}
}