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
	MatchId,
	RoomStateRequestMessage,
	PlayerListMessage,
	FindEmptyTableMessage,
	FoundEmptyTableMessage,
	JoinTableMessage,
	JoinedTableMessage,
	PlayerStateRequestMessage,
	PlayerStateMessage,
	RoomActionResponseMessage
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundRoomMessage|OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.maxTableCount, configuration.maxPlayerCount, messageBroadcaster);
	variable Instant lastNotification = Instant(0);
	
	function findRoom(RoomId roomId) => room.id == roomId then room else null;
	function findTable(TableId tableId) => room.findTable(tableId);
	function findMatch(MatchId matchId) => room.findMatch(matchId);
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.definePlayer(message.playerInfo)) {
					return RoomActionResponseMessage(message.playerId, message.roomId, true);
				} else {
					return RoomActionResponseMessage(message.playerId, message.roomId, false);
				}
			}
			case (is LeaveRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.removePlayer(message.playerId)) {
					if (exists match = player.match, match.hasGame) {
						gameCommander(EndGameMessage(match.id, player.id));
					}
					return RoomActionResponseMessage(message.playerId, message.roomId, true);
				} else {
					return RoomActionResponseMessage(message.playerId, message.roomId, false);
				}
			}
			case (is FindMatchTableMessage) {
				if (exists room = findRoom(message.roomId), exists table = room.findMatchTable(message.playerId)) {
					return FoundMatchTableMessage(message.playerId, message.roomId, table.index);
				} else {
					return FoundMatchTableMessage(message.playerId, message.roomId, null);
				}
			}
			case (is FindEmptyTableMessage) {
				if (exists room = findRoom(message.roomId), exists table = room.findEmptyTable(message.playerId)) {
					return FoundEmptyTableMessage(message.playerId, message.roomId, table.index);
				} else {
					return FoundEmptyTableMessage(message.playerId, message.roomId, null);
				}
			}
			case (is RoomStateRequestMessage) {
				if (exists room = findRoom(message.roomId)) {
					return PlayerListMessage(message.roomId, room.createPlayerList());
				} else {
					return PlayerListMessage(message.roomId);
				}
			}
			case (is PlayerStateRequestMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId)) {
					return PlayerStateMessage(message.roomId, player.state, player.match?.state);
				} else {
					return PlayerStateMessage(message.roomId, null, null);
				}
			}
		}
	}
	
	shared OutboundTableMessage processTableMessage(InboundTableMessage message) {
		try (lock) {
			switch (message)
			case (is JoinTableMessage) {
				if (exists table = findTable(message.tableId), exists player = room.findPlayer(message.playerId), table.sitPlayer(player)) {
					return JoinedTableMessage(message.playerId, message.tableId, true);
				} else {
					return JoinedTableMessage(message.playerId, message.tableId, false);
				}
			}
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
					return TableStateResponseMessage(message.playerId, message.tableId, table.queueSize, table.findPlayer(message.playerId) exists, room.findMatchState(message.tableId, message.playerId), true);
				} else {
					return TableStateResponseMessage(message.playerId, message.tableId, 0, false, null, false);
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
				busyTableCount = room.tableCountLimit - freeTableCount;
				maxTableCount = room.maxTableCount;
				activeMatchCount = room.matchCount;
				maxMatchCount = room.maxMatchCount;
				totalMatchCount = room.createdMatchCount;
			};
		}
	}
	
	shared void periodicNotification(Instant currentTime) {
		try (lock) {
			value playerCount = room.playerCount;
			if (playerCount > 0 && lastNotification.durationTo(currentTime).milliseconds * configuration.maxPlayerMessageRate > playerCount) {
				value message = room.createPlayerListDelta();
				if (exists message) {
					messageBroadcaster(message);
				}
				lastNotification = currentTime;
			}
		}
	}
}