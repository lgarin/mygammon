import backgammon.server.room {
	RoomConfiguration,
	Room,
	Player,
	Match
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
	RoomActionResponseMessage,
	PlayerRosterInboundMessage,
	PlayerStatisticUpdateMessage
}

import ceylon.time {
	Instant
}

shared final class MatchRoom(RoomConfiguration configuration, Anything(OutboundRoomMessage|OutboundTableMessage|OutboundMatchMessage) messageBroadcaster, Anything(InboundGameMessage) gameCommander, Anything(PlayerRosterInboundMessage) playerRepository) {
	
	value lock = ObtainableLock(); 
	value room = Room(configuration.roomId, configuration.roomSize, configuration.matchBet, messageBroadcaster);
	variable Instant lastNotification = Instant(0);
	
	function findRoom(RoomId roomId) => room.id == roomId then room else null;
	
	function enterRoom(EnterRoomMessage message) {
		if (exists room = findRoom(message.roomId), exists player = room.definePlayer(message.playerInfo, message.playerStatistic)) {
			player.markActive();
			return RoomActionResponseMessage(message.playerId, message.roomId, true);
		} else {
			return RoomActionResponseMessage(message.playerId, message.roomId, false);
		}
	}
	
	function leaveRoom(LeaveRoomMessage message) {
		if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId)) {
			if (exists match = player.match, match.hasGame) {
				gameCommander(EndGameMessage(match.id, player.id));
			}
			return RoomActionResponseMessage(message.playerId, message.roomId, room.removePlayer(player));
		} else {
			return RoomActionResponseMessage(message.playerId, message.roomId, false);
		}
	}
	
	void handlePlayerChange(Player player) {
		if (exists delta = player.applyStatisticDelta()) {
			room.registerPlayerChange(player);
			playerRepository(PlayerStatisticUpdateMessage(player.info, delta));
		}
	}
	
	function findMatchTable(FindMatchTableMessage message) {
		if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId), exists table = room.findMatchTable(player)) {
			player.markActive();
			handlePlayerChange(player);
			return FoundMatchTableMessage(message.playerId, message.roomId, table.index);
		} else {
			return FoundMatchTableMessage(message.playerId, message.roomId, null);
		}
	}
	
	function findEmptyTable(FindEmptyTableMessage message) {
		if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId), exists table = room.findEmptyTable(player)) {
			player.markActive();
			handlePlayerChange(player);
			return FoundEmptyTableMessage(message.playerId, message.roomId, table.index);
		} else {
			return FoundEmptyTableMessage(message.playerId, message.roomId, null);
		}
	}
	
	function getRoomState(RoomStateRequestMessage message) {
		if (exists room = findRoom(message.roomId)) {
			return PlayerListMessage(message.roomId, room.createPlayerList());
		} else {
			return PlayerListMessage(message.roomId);
		}
	}
	
	function getPlayerState(PlayerStateRequestMessage message) {
		if (exists room = findRoom(message.roomId), exists player = room.findPlayer(message.playerId)) {
			return PlayerStateMessage(message.roomId, player.state, player.match?.state);
		} else {
			return PlayerStateMessage(message.roomId, null, null);
		}
	}
	
	shared OutboundRoomMessage processRoomMessage(InboundRoomMessage message) {
		try (lock) {
			switch (message)
			case (is EnterRoomMessage) {
				return enterRoom(message);
			}
			case (is LeaveRoomMessage) {
				return leaveRoom(message);
			}
			case (is FindMatchTableMessage) {
				return findMatchTable(message);
			}
			case (is FindEmptyTableMessage) {
				return findEmptyTable(message);
			}
			case (is RoomStateRequestMessage) {
				return getRoomState(message);
			}
			case (is PlayerStateRequestMessage) {
				return getPlayerState(message);
			}
		}
	}
	
	function joinTable(JoinTableMessage message) {
		if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId), table.sitPlayer(player)) {
			player.markActive();
			handlePlayerChange(player);
			room.createMatch(table); // TODO why?
			return JoinedTableMessage(message.playerId, message.tableId, player.info);
		} else {
			return JoinedTableMessage(message.playerId, message.tableId, null);
		}
	}
	
	function leaveTable(LeaveTableMessage message) {
		if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId)) {
			player.markActive();
			handlePlayerChange(player);
			if (exists match = player.match, match.hasGame) {
				gameCommander(EndGameMessage(match.id, player.id));
			}
			return LeftTableMessage(message.playerId, message.tableId, table.removePlayer(player));
		} else {
			return LeftTableMessage(message.playerId, message.tableId, false);
		}
	}
	
	function getTableState(TableStateRequestMessage message) {
		if (exists room = findRoom(message.roomId), exists table = room.findTable(message.tableId), exists player = room.findPlayer(message.playerId)) {
			player.markActive();
			if (message.current) {
				return TableStateResponseMessage(message.playerId, message.tableId, table.matchState, table.queueState, true);
			} else {
				// TODO replace with a MatchStateRequestMessage
				return TableStateResponseMessage(message.playerId, message.tableId, player.findRecentMatchState(table.id), table.queueState, true);
			}
		} else {
			return TableStateResponseMessage(message.playerId, message.tableId, null, [], false);
		}
	}
	
	shared OutboundTableMessage processTableMessage(InboundTableMessage message) {
		try (lock) {
			switch (message)
			case (is JoinTableMessage) {
				return joinTable(message);
			}
			case (is LeaveTableMessage) {
				return leaveTable(message);
			}
			case (is TableStateRequestMessage) {
				return getTableState(message);
			}
		}
	}
	
	function acceptMatch(AcceptMatchMessage message) {
		if (exists room = findRoom(message.roomId), exists match = room.findCurrentMatch(message.matchId), exists player = room.findPlayer(message.playerId), match.markReady(message.playerId)) {
			player.markActive();
			if (match.gameStarted) {
				handlePlayerChange(match.player1);
				handlePlayerChange(match.player2);
				gameCommander(StartGameMessage(match.id, match.player1.id, match.player2.id));
			}
			return AcceptedMatchMessage(message.playerId, message.matchId, true);
		} else {
			return AcceptedMatchMessage(message.playerId, message.matchId, false);
		}
	}
	
	function endMatch(EndMatchMessage message) {
		function bonusScore(Match match) => configuration.bonusScorePercentage * (match.player1.statistic.score - match.player2.statistic.score).magnitude / 100;
		
		if (exists room = findRoom(message.roomId), exists match = room.findCurrentMatch(message.matchId), match.end(message.playerId, message.winnerId, message.score + bonusScore(match))) {
			if (message.isNormalWin) {
				match.player1.markActive();
				match.player2.markActive();
			} else if (message.isSurrenderWin, exists winner = match.findPlayer(message.winnerId)) {
				winner.markActive();
			}
			handlePlayerChange(match.player1);
			handlePlayerChange(match.player2);
			return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, message.score, true);
		} else {
			return MatchEndedMessage(message.playerId, message.matchId, message.winnerId, message.score, false);
		}
	}
	
	shared OutboundMatchMessage processMatchMessage(InboundMatchMessage message) {
		try (lock) {
			switch (message)
			case (is AcceptMatchMessage) {
				return acceptMatch(message);
			}
			case (is EndMatchMessage) {
				return endMatch(message);
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
			return MatchRoomStatistic {
				roomId = room.id;
				activePlayerCount = room.playerCount;
				maxPlayerCount = room.maxPlayerCount;
				totalPlayerCount = room.createdPlayerCount;
				busyTableCount = room.busyTableCount;
				maxTableCount = room.maxTableCount;
				totalTableCount = room.createdTableCount;
				activeMatchCount = room.matchCount;
				maxMatchCount = room.maxMatchCount;
				totalMatchCount = room.createdMatchCount;
			};
		}
	}
	
	shared void periodicNotification(Instant currentTime) {
		try (lock) {
			if (room.playerListDeltaSize > 0 && lastNotification.durationTo(currentTime).milliseconds * configuration.maxPlayerMessageRate > room.playerCount) {
				messageBroadcaster(room.createPlayerListDelta());
				lastNotification = currentTime;
			}
		}
	}
}