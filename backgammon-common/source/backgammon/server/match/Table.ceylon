import backgammon.common {
	JoiningMatchMessage,
	TableMessage,
	TableId,
	RoomId,
	OutboundTableMessage,
	OutboundMatchMessage,
	InboundGameMessage,
	PlayerInfo,
	MatchState
}

import ceylon.collection {
	HashSet,
	linked,
	ArrayList
}
import ceylon.test {
	test
}
import ceylon.time {
	Duration
}

final class Table(shared Integer index, shared RoomId roomId, shared Duration maxMatchJoinTime, Anything(OutboundTableMessage|OutboundMatchMessage) messageBroadcaster) {
	
	shared TableId id = TableId(roomId.string, index + 1);
	
	variable Match? match = null;
	
	value playerQueue = HashSet<Player>(linked);
	
	shared Boolean free => playerQueue.empty;
	
	shared Integer queueSize => playerQueue.size;
	
	shared void publish(OutboundTableMessage|OutboundMatchMessage message) {
		messageBroadcaster(message);
	}
	
	shared void send(InboundGameMessage message) {
		// TODO
	}
	
	function createMatch(Player player1, Player player2) {
		value currentMatch = Match(player1, player2, this);
		match = currentMatch;
		return player1.joinMatch(currentMatch) && player2.joinMatch(currentMatch);
	}
	
	shared Boolean sitPlayer(Player player) {
		if (playerQueue.contains(player)) {
			return false;
		} else if (match exists){
			playerQueue.add(player);
			return false;
		} else if (exists opponent = playerQueue.first) {
			return playerQueue.add(player) && createMatch(opponent, player);
		} else if (playerQueue.empty) {
			return playerQueue.add(player);
		} else {
			playerQueue.add(player);
			return false;
		}
	}
	
	shared Boolean removePlayer(Player player) {
		return playerQueue.remove(player);
	}
	
	shared Boolean removeMatch(Match currentMatch) {
		if (exists matchImpl = match, matchImpl === currentMatch) {
			match = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared MatchState? matchInfo {
		if (exists currentMatch = match) {
			return currentMatch.state;
		} else {
			return null;
		}
	}
}

class TableTest() {

	value messageList = ArrayList<TableMessage>();
	value table = Table(0, RoomId("room"), Duration(1000), messageList.add);
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), null);
	
	test
	shared void newTableIsFree() {
		assert (table.free);
	}
	
	test
	shared void sitSinglePlayer() {
		value result = table.sitPlayer(makePlayer("player1"));
		assert (result);
		assert (messageList.empty);
	}
	
	test
	shared void sitSamePlayerTwice() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.sitPlayer(player);
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void sitTwoPlayers() {
		value result1 = table.sitPlayer(makePlayer("player1"));
		assert (result1);
		value result2 = table.sitPlayer(makePlayer("player2"));
		assert (result2);
		assert (messageList.count((TableMessage element) => element is JoiningMatchMessage) == 2);
	}
	
	test
	shared void queuePlayer() {
		table.sitPlayer(makePlayer("player1"));
		table.sitPlayer(makePlayer("player2"));
		
		value result = table.sitPlayer(makePlayer("player3"));
		assert (!result);
		assert (table.queueSize == 3);
	}
	
	test
	shared void removeUnknownPlayer() {
		value result = table.removePlayer(makePlayer("player1"));
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void removeKnownPlayer() {
		value player = makePlayer("player1");
		table.sitPlayer(player);
		value result = table.removePlayer(player);
		assert (result);
		assert (messageList.empty);
	}
}