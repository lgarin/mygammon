import backgammon.server.room {
	RoomConfiguration,
	Room,
	Table
}
import backgammon.server.util {
	ObtainableLock
}
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
	StartGameMessage,
	InboundGameMessage,
	EndMatchMessage,
	MatchEndedMessage,
	RoomId,
	TableId,
	PlayerId,
	EndGameMessage
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.tableCount, messageBroadcaster);
	variable Integer createdPlayerCount = 0;
	
	function findRoom(RoomId roomId) => room.id == roomId then room else null;
	function findTable(TableId tableId) => room.findTable(tableId);
	function findPlayer(PlayerId playerId) => room.players[playerId];
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.addPlayer(message.playerInfo)) {
					createdPlayerCount++;
					return EnteredRoomMessage(message.playerId, message.roomId, true);
				} else {
					return EnteredRoomMessage(message.playerId, message.roomId, false);
				}
			}
			case (is LeaveRoomMessage) {
				// TODO not used
				if (exists room = findRoom(message.roomId), exists player = room.removePlayer(message.playerId)) {
					return LeftRoomMessage(message.playerId, message.roomId, true);
				} else {
					return LeftRoomMessage(message.playerId, message.roomId, false);
				}
			}
			case (is FindMatchTableMessage) {
				if (exists room = findRoom(message.roomId), exists table = room.findMatchTable(message.playerId)) {
					return FoundMatchTableMessage(message.playerId, message.roomId, table.index);
				} else {
					return FoundMatchTableMessage(message.playerId, message.roomId, null);
				}
			}
		}
	}
	
	shared OutboundTableMessage processTableMessage(InboundTableMessage message) {
		try (lock) {
			switch (message)
			case (is LeaveTableMessage) {
				if (exists player = findPlayer(message.playerId), exists matchId = player.gameMatchId) {
					gameCommander(EndGameMessage(matchId, player.id));
				}
				
				if (exists table = findTable(message.tableId), exists player = table.removePlayer(message.playerId)) {
					return LeftTableMessage(message.playerId, message.tableId, true);
				} else {
					return LeftTableMessage(message.playerId, message.tableId, false);
				}
			}
			case (is TableStateRequestMessage) {
				if (exists table = findTable(message.tableId)) {
					return TableStateResponseMessage(message.playerId, message.tableId, table.getTableMatch(message.playerId), true);
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
				if (exists table = findTable(message.tableId), exists match = table.acceptMatch(message.matchId, message.playerId)) {
					if (match.gameStarted) {
						gameCommander(StartGameMessage(match.id, match.player1Id, match.player2Id));
					}
					return AcceptedMatchMessage(message.playerId, message.matchId, true);
				} else {
					return AcceptedMatchMessage(message.playerId, message.matchId, false);
				}
			}
			case (is EndMatchMessage) {
				if (exists table = findTable(message.tableId), exists match = table.endMatch(message.matchId, message.winnerId)) {
					messageBroadcaster(MatchEndedMessage(message.playerId, message.matchId, message.winnerId, true));
					return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, true);
				} else {
					return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, false);
				}
			}
		}
	}

	shared void periodicCleanup(Instant currentTime) {
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