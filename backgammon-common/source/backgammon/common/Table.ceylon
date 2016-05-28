import ceylon.collection {
	HashSet,
	linked
}

shared interface Table {

	shared formal Boolean free;
	
	shared formal Integer queueSize;
}

class TableImpl(shared Integer index) satisfies Table {
	
	variable GameImpl? game = null;
	
	value playerQueue = HashSet<PlayerImpl>(linked);
	
	shared actual Boolean free => playerQueue.empty;
	
	shared actual Integer queueSize => playerQueue.size;
	
	void createGame(PlayerImpl player1, PlayerImpl player2) {
		value currentGame = GameImpl(player1, player2, this);
		game = currentGame;
		player1.joinGame(currentGame);
		player2.joinGame(currentGame);
	}
	
	shared Boolean sitPlayer(PlayerImpl player) {
		if (exists currentGame = game){
			playerQueue.add(player);
			return false;
		} else if (exists opponent = playerQueue.first) {
			playerQueue.add(player);
			createGame(opponent, player);
			return true;
		} else if (playerQueue.empty) {
			playerQueue.add(player);
			player.waitOpponent();
			return true;
		} else {
			playerQueue.add(player);
			return false;
		}
	}
	
	shared Boolean removePlayer(PlayerImpl player) {
		return playerQueue.remove(player);
	}
	
	shared Boolean removeGame(GameImpl currentGame) {
		if (exists gameImpl = game, gameImpl === currentGame) {
			game = null;
			return true;
		} else {
			return false;
		}
	}
}