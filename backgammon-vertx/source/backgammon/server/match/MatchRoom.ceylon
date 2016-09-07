import backgammon.server.room {
	RoomConfiguration,
	Room
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
	EndGameMessage,
	MatchId
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.tableCount, messageBroadcaster);
	
	function findRoom(RoomId roomId) => room.id == roomId then room else null;
	function findTable(TableId tableId) => room.findTable(tableId);
	function findMatch(MatchId matchId) => room.findMatch(matchId);
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.definePlayer(message.playerInfo)) {
					return EnteredRoomMessage(message.playerId, message.roomId, true);
				} else {
					return EnteredRoomMessage(message.playerId, message.roomId, false);
				}
			}
			case (is LeaveRoomMessage) {
				// TODO not used
				if (exists room = findRoom(message.roomId), exists player = room.removePlayer(message.playerId)) {
					if (exists match = player.match, match.hasGame) {
						gameCommander(EndGameMessage(match.id, player.id));
					}
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
				if (exists table = findTable(message.tableId), exists player = table.removePlayer(message.playerId)) {
					if (exists match = player.match, match.hasGame) {
						gameCommander(EndGameMessage(match.id, player.id));
					}
					return LeftTableMessage(message.playerId, message.tableId, true);
				} else {
					return LeftTableMessage(message.playerId, message.tableId, false);
				}
			}
			case (is TableStateRequestMessage) {
				if (exists table = findTable(message.tableId), exists room = findRoom(message.roomId)) {
					return TableStateResponseMessage(message.playerId, message.tableId, table.findPlayer(message.playerId) exists, room.findMatchState(message.tableId, message.playerId), true);
				} else {
					return TableStateResponseMessage(message.playerId, message.tableId, false, null, false);
				}
			}
		}
	}
	
	shared OutboundMatchMessage processMatchMessage(InboundMatchMessage message) {
		try (lock) {
			switch (message)
			case (is AcceptMatchMessage) {
				if (exists match = findMatch(message.matchId), match.markReady(message.playerId)) {
					if (match.gameStarted) {
						gameCommander(StartGameMessage(match.id, match.player1.id, match.player2.id));
					}
					return AcceptedMatchMessage(message.playerId, message.matchId, true);
				} else {
					return AcceptedMatchMessage(message.playerId, message.matchId, false);
				}
			}
			case (is EndMatchMessage) {
				if (exists match = findMatch(message.matchId), match.end(message.playerId, message.winnerId, message.score)) {
					return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, message.score, true);
				} else {
					return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, message.score, false);
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
			value freeTableCount = room.freeTableCount;
			return MatchRoomStatistic {
				roomId = room.id;
				activePlayerCount = room.playerCount;
				maxPlayerCount = room.maxPlayerCount;
				totalPlayerCount = room.createdPlayerCount;
				freeTableCount = room.freeTableCount;
				busyTableCount = room.tableCount - freeTableCount;
				maxTableCount = room.maxTableCount;
				activeMatchCount = room.matchCount;
				maxMatchCount = room.maxMatchCount;
				totalMatchCount = room.createdMatchCount;
			};
		}
	}
}