import ceylon.collection {
	HashSet,
	linked,
	ArrayList
}
import ceylon.test {

	test
}

shared interface Table {

	shared formal Boolean free;
	
	shared formal Integer queueSize;
}

class TableImpl(shared Integer index) satisfies Table {
	
	variable MatchImpl? match = null;
	
	value playerQueue = HashSet<PlayerImpl>(linked);
	
	shared actual Boolean free => playerQueue.empty;
	
	shared actual Integer queueSize => playerQueue.size;
	
	void createMatch(PlayerImpl player1, PlayerImpl player2) {
		value currentMatch = MatchImpl(player1, player2, this);
		match = currentMatch;
		player1.joinMatch(currentMatch);
		player2.joinMatch(currentMatch);
	}
	
	shared Boolean sitPlayer(PlayerImpl player) {
		if (playerQueue.contains(player)) {
			return false;
		} else if (match exists){
			playerQueue.add(player);
			return false;
		} else if (exists opponent = playerQueue.first) {
			playerQueue.add(player);
			createMatch(opponent, player);
			return true;
		} else if (playerQueue.empty) {
			playerQueue.add(player);
			return true;
		} else {
			playerQueue.add(player);
			return false;
		}
	}
	
	shared Boolean removePlayer(PlayerImpl player) {
		return playerQueue.remove(player);
	}
	
	shared Boolean removeMatch(MatchImpl currentMatch) {
		if (exists matchImpl = match, matchImpl === currentMatch) {
			match = null;
			return true;
		} else {
			return false;
		}
	}
}

class TableTest() {
	
	value table = TableImpl(0);
	
	value messageList = ArrayList<ApplicationMessage>();
	world.messageListener = messageList.add;
	
	test
	shared void newTableIsFree() {
		assert (table.free);
	}
	
	test
	shared void sitSinglePlayer() {
		value result = table.sitPlayer(PlayerImpl("player1"));
		assert (result);
		assert (messageList.empty);
	}
	
	test
	shared void sitSamePlayerTwice() {
		value player = PlayerImpl("player1");
		table.sitPlayer(player);
		value result = table.sitPlayer(player);
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void sitTwoPlayers() {
		value result1 = table.sitPlayer(PlayerImpl("player1"));
		assert (result1);
		value result2 = table.sitPlayer(PlayerImpl("player2"));
		assert (result2);
		assert (messageList.count((ApplicationMessage element) => element is JoiningMatchMessage) == 2);
	}
	
	test
	shared void queuePlayer() {
		table.sitPlayer(PlayerImpl("player1"));
		table.sitPlayer(PlayerImpl("player2"));
		
		value result = table.sitPlayer(PlayerImpl("player3"));
		assert (!result);
		assert (table.queueSize == 3);
	}
	
	test
	shared void removeUnknownPlayer() {
		value result = table.removePlayer(PlayerImpl("player1"));
		assert (!result);
		assert (messageList.empty);
	}
	
	test
	shared void removeKnownPlayer() {
		value player = PlayerImpl("player1");
		table.sitPlayer(player);
		value result = table.removePlayer(player);
		assert (result);
		assert (messageList.empty);
	}
}