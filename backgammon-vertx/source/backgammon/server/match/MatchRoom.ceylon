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
	EndGameMessage,
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
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.definePlayer(message.playerInfo)) {
					player.markActive();
					return RoomActionResponseMessage(message.playerId, message.roomId, true);
				} else {
					return RoomActionResponseMessage(message.playerId, message.roomId, false);
				}
			}
			case (is LeaveRoomMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId)) {
					if (exists match = player.match, match.hasGame) {
						gameCommander(EndGameMessage(match.id, player.id));
					}
					return RoomActionResponseMessage(message.playerId, message.roomId, room.removePlayer(player));
				} else {
					return RoomActionResponseMessage(message.playerId, message.roomId, false);
				}
			}
			case (is FindMatchTableMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId), exists table = room.findMatchTable(player)) {
					player.markActive();
					return FoundMatchTableMessage(message.playerId, message.roomId, table.index);
				} else {
					return FoundMatchTableMessage(message.playerId, message.roomId, null);
				}
			}
			case (is FindEmptyTableMessage) {
				if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId), exists table = room.findEmptyTable(player)) {
					player.markActive();
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
				if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId), table.sitPlayer(player)) {
					player.markActive();
					room.registerPlayerChange(player);
					return JoinedTableMessage(message.playerId, message.tableId, player.info);
				} else {
					return JoinedTableMessage(message.playerId, message.tableId, null);
				}
			}
			case (is LeaveTableMessage) {
				if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId)) {
					player.markActive();
					room.registerPlayerChange(player);
					if (exists match = player.match, match.hasGame) {
						gameCommander(EndGameMessage(match.id, player.id));
					}
					return LeftTableMessage(message.playerId, message.tableId, table.removePlayer(player));
				} else {
					return LeftTableMessage(message.playerId, message.tableId, false);
				}
			}
			case (is TableStateRequestMessage) {
				if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId)) {
					player.markActive();
					if (message.current) {
						return TableStateResponseMessage(message.playerId, message.tableId, table.matchState, table.queueState, true);
					} else {
						return TableStateResponseMessage(message.playerId, message.tableId, player.findRecentMatchState(table.id), table.queueState, true);
					}
				} else {
					return TableStateResponseMessage(message.playerId, message.tableId, null, [], false);
				}
			}
		}
	}
	
	shared OutboundMatchMessage processMatchMessage(InboundMatchMessage message) {
		try (lock) {
			switch (message)
			case (is AcceptMatchMessage) {
				if (exists room = findRoom(message.roomId), exists match = room.findMatch(message.matchId), exists player = room.findPlayer(message.playerId), match.markReady(message.playerId)) {
					player.markActive();
					if (match.gameStarted) {
						gameCommander(StartGameMessage(match.id, match.player1.id, match.player2.id));
					}
					return AcceptedMatchMessage(message.playerId, message.matchId, true);
				} else {
					return AcceptedMatchMessage(message.playerId, message.matchId, false);
				}
			}
			case (is EndMatchMessage) {
				if (exists room = findRoom(message.roomId), exists match = room.findMatch(message.matchId), match.end(message.playerId, message.winnerId, message.score)) {
					room.removeMatch(match.id);
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
			if (room.playerListDeltaSize > 0 && lastNotification.durationTo(currentTime).milliseconds * configuration.maxPlayerMessageRate > room.playerCount) {
				value message = room.createPlayerListDelta();
				if (exists message) {
					messageBroadcaster(message);
				}
				lastNotification = currentTime;
			}
		}
	}
}