import backgammon.common {
	InboundRoomMessage,
	EnterRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	LeaveRoomMessage,
	FindMatchTableMessage,
	EnteredRoomMessage,
	LeftRoomMessage,
	FoundMatchTableMessage,
	OutboundRoomMessage,
	TableStateRequestMessage,
	TableStateResponseMessage
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
				return LeftRoomMessage(player.id, room.id, true);
			}
			return LeftRoomMessage(message.playerId, room.id, false);
		}
		case (is FindMatchTableMessage) {
			if (exists player = room.players[message.playerId], player.findMatchTable()) {
				return FoundMatchTableMessage(player.id, room.id, player.tableIndex);
			}
			return FoundMatchTableMessage(message.playerId, room.id, null);
		}
		case (is TableStateRequestMessage) {
			if (exists table = room.tables[message.table]) {
				return TableStateResponseMessage(message.playerId, message.roomId, message.table, table.matchInfo, true);
			} else {
				return TableStateResponseMessage(message.playerId, message.roomId, message.table, null, false);
			}
		}
	}
	
	shared OutboundRoomMessage|OutboundTableMessage processRoomMessage(InboundRoomMessage message, Instant currentTime) {
		// TODO implement flooding control
		try (lock) {
			return process(message);
		}
	}

	shared void removeInactivePlayers(Instant currentTime) {
		try (lock) {
			room.removeInactivePlayers(currentTime.plus(configuration.playerInactiveTimeout));
		}
	}
}