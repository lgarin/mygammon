import backgammon.server.room {
	Room,
	Player,
	RoomSize,
	MatchBet
}
import backgammon.shared {
	JoinedTableMessage,
	CreatedMatchMessage,
	RoomMessage,
	PlayerInfo,
	PlayerState,
	PlayerStatistic,
	TableId
}

import ceylon.collection {
	ArrayList
}
import ceylon.test {
	test
}

class RoomTest() {
	value initialPlayerBalance = 1000;
	value matchBet = MatchBet(10, 18);
	value roomSize = RoomSize(3, 10);
	value messageList = ArrayList<RoomMessage>();
	value room = Room("test1", roomSize, matchBet, messageList.add);
	
	function makePlayerInfo(String id) => PlayerInfo(id, id);
	
	test
	shared void newRoomHasNoPlayer() {
		assert (room.playerCount == 0);
		assert (room.createPlayerList().size == 0);
	}

	test
	shared void newRoomHasOnlyFreeTables() {
		assert (room.freeTableCount == roomSize.tableCount);
	}
	
	test
	shared void addNewPlayer() {
		value result = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (result exists);
		assert (room.playerCount == 1);
	}
	
	test
	shared void createDeltaForNewPlayer() {
		room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (room.playerListDeltaSize == 1);
		value result = room.createPlayerListDelta();
		assert (room.playerListDeltaSize == 0);
		assert (result.newPlayers == [PlayerState(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance), null, null)]);
		assert (result.updatedPlayers.empty);
		assert (result.oldPlayers.empty);
	}
	
	test
	shared void addSamePlayerIdTwice() {
		room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		value result = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (result exists);
		assert (room.playerCount == 1);
	}
	
	test
	shared void removeExistingPlayer() {
		value player = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player);
		room.removePlayer(player);
		assert (!room.findPlayer(player.id) exists);
	}
	
	test
	shared void createDeltaForOldPlayer() {
		value player = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player);
		room.removePlayer(player);
		assert (room.playerListDeltaSize == 2);
		value result = room.createPlayerListDelta();
		assert (room.playerListDeltaSize == 0);
		assert (result.newPlayers == [PlayerState(player.info, PlayerStatistic(initialPlayerBalance), null, null)]);
		assert (result.oldPlayers == [PlayerState(player.info, PlayerStatistic(initialPlayerBalance), null, null)]);
		assert (result.updatedPlayers.empty);
	}
	
	test
	shared void removeNonExistingPlayer() {
		value player = Player(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		room.removePlayer(player);
		assert (!room.findPlayer(player.id) exists);
	}
	
	test
	shared void sitPlayerWithoutOpponent() {
		value player = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player);
		value result = room.findMatchTable(player);
		assert (result exists);
		assert (messageList.count((element) => element is JoinedTableMessage) == 1);
		assert (messageList.count((element) => element is CreatedMatchMessage) == 0);
	}
	
	test
	shared void sitPlayerWithOpponent() {
		value player1 = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player1);
		value player2 = room.definePlayer(makePlayerInfo("player2"), PlayerStatistic(initialPlayerBalance));
		assert (exists player2);
		value result1 = room.findMatchTable(player1);
		assert (result1 exists);
		value result2 = room.findMatchTable(player2);
		assert (result2 exists);
		assert (messageList.count((element) => element is JoinedTableMessage) == 2);
		assert (messageList.count((element) => element is CreatedMatchMessage) == 1);
	}
	
	test
	shared void openNewTable() {
		value player = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player);
		value result = room.findEmptyTable(player);
		assert (exists result);
		assert (player.isAtTable(result.id));
		assert (messageList.count((element) => element is JoinedTableMessage) == 1);
		assert (messageList.count((element) => element is CreatedMatchMessage) == 0);
	}
	
	test
	shared void openNewTableWithoutEmptyTable() {
		for (i in 1..roomSize.tableCount) {
			value player = room.definePlayer(makePlayerInfo("player``i``"), PlayerStatistic(initialPlayerBalance));
			assert (exists player);
			value result = room.findEmptyTable(player);
			assert (exists result);
		}
		value player = room.definePlayer(makePlayerInfo("playerN"), PlayerStatistic(initialPlayerBalance));
		assert (exists player);
		value result = room.findEmptyTable(player);
		assert (!result exists);
	}
	
	test
	shared void createMatch() {
		value player1 = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player1);
		value player2 = room.definePlayer(makePlayerInfo("player2"), PlayerStatistic(initialPlayerBalance));
		assert (exists player2);
		value table = room.findTable(TableId(room.roomId, 1));
		assert (exists table);
		table.sitPlayer(player1);
		table.sitPlayer(player2);
		value result = room.createMatch(table);
		assert (result);
		assert (player1.match exists);
		assert (player2.match exists);
	}
	
	test
	shared void createMatchWithoutOpponent() {
		value player1 = room.definePlayer(makePlayerInfo("player1"), PlayerStatistic(initialPlayerBalance));
		assert (exists player1);
		value table = room.findTable(TableId(room.roomId, 1));
		assert (exists table);
		table.sitPlayer(player1);
		value result = room.createMatch(table);
		assert (!result);
	}
}