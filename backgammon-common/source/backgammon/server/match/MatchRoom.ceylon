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
	TableStateResponseMessage,
	InboundMatchMessage,
	AcceptMatchMessage,
	AcceptedMatchMessage,
	InboundTableMessage,
	LeaveTableMessage,
	LeftTableMessage,
	InboundGameMessage,
	StartGameMessage
}
import backgammon.server.common {
	RoomConfiguration,
	ObtainableLock
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.tableCount, messageBroadcaster);
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
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
		}
	}
	
	shared OutboundTableMessage processTableMessage(InboundTableMessage message) {
		try (lock) {
			switch (message)
			case (is LeaveTableMessage) {
				if (exists player = room.players[message.playerId], player.leaveTable()) {
					return LeftTableMessage(message.playerId, message.tableId, true);
				} else {
					return LeftTableMessage(message.playerId, message.tableId, false);
				}
			}
			case (is TableStateRequestMessage) {
				if (exists table = room.tables[message.tableId.table]) {
					return TableStateResponseMessage(message.playerId, message.tableId, table.matchInfo, true);
				} else {
					return TableStateResponseMessage(message.playerId, message.tableId, null, false);
				}
			}
		}
	}
	
	shared OutboundMatchMessage processMatchMessage(InboundMatchMessage message) {
		try (lock) {
			switch (message)
			case (is AcceptMatchMessage) {
				if (exists player = room.players[message.playerId], player.acceptMatch()) {
					if (exists matchId = player.matchId, exists opponentId = player.gameOpponentId) {
						gameCommander(StartGameMessage(matchId, message.playerId, opponentId));
					}
					return AcceptedMatchMessage(message.playerId, message.matchId, true);
				} else {
					return AcceptedMatchMessage(message.playerId, message.matchId, false);
				}
			}
		}
	}

	shared void removeInactivePlayers(Instant currentTime) {
		try (lock) {
			room.removeInactivePlayers(currentTime.minus(configuration.playerInactiveTimeout));
		}
	}
}