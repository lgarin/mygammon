import backgammon.shared {
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
	EndGameMessage,
	StartGameMessage,
	InboundGameMessage
}
import ceylon.time {
	Instant
}
import backgammon.server.util {

	ObtainableLock
}
import backgammon.server.room {

	RoomConfiguration,
	Room,
	Table
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.tableCount, messageBroadcaster);
	variable Integer createdPlayerCount = 0;
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				if (exists player = room.players[message.playerId]) {
					return EnteredRoomMessage(player.id, room.id, false);
				}
				value player = room.createPlayer(message.playerInfo);
				createdPlayerCount++;
				return EnteredRoomMessage(player.id, room.id, true);
			}
			case (is LeaveRoomMessage) {
				if (exists player = room.players[message.playerId], player.leaveRoom()) {
					if (exists matchId = player.previousMatchId) {
						gameCommander(EndGameMessage(matchId, player.id));
					}
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
					if (exists matchId = player.previousMatchId) {
						gameCommander(EndGameMessage(matchId, player.id));
					}
					return LeftTableMessage(message.playerId, message.tableId, true);
				} else {
					return LeftTableMessage(message.playerId, message.tableId, false);
				}
			}
			case (is TableStateRequestMessage) {
				// TODO player may not be on this table
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
	
	shared MatchRoomStatistic statistic {
		try (lock) {
			value freeTableCount = room.tables.count((Table element) => element.free);
			return MatchRoomStatistic(room.id, room.players.size, createdPlayerCount, freeTableCount, room.tableCount - freeTableCount);
		}
	}
}