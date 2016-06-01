import ceylon.time {

	Duration,
	Instant,
	now
}
import backgammon.game {

	Game,
	makeGame,
	GameMessage
}
import ceylon.test {

	test
}
import ceylon.collection {

	ArrayList
}
shared interface Match {
	shared formal Duration remainingJoinTime;
	
	shared formal Player player1;
	
	shared formal Player player2;
	
	shared formal Player? winner;
	
	shared formal Table table;
	
	shared formal Game? game;
}

class MatchImpl(shared actual PlayerImpl player1, shared actual PlayerImpl player2, shared actual TableImpl table) satisfies Match {
	
	shared actual variable Game? game = null;
	
	shared actual variable PlayerImpl? winner = null;
	
	Instant creationTime = now();
	
	value diceRoller = DiceRoller();
	
	value gameId = "``table.roomId``-``table.index``-``creationTime.millisecondsOfEpoch``";
	
	shared actual Duration remainingJoinTime => Duration(world.maximumGameJoinTime.milliseconds - creationTime.durationTo(now()).milliseconds);

	class PlayerStatus() {
		shared variable Boolean ready = false;
	}
	
	[PlayerStatus, PlayerStatus] playerStates = [PlayerStatus(), PlayerStatus()];
	
	Integer? playerIndex(PlayerImpl player) {
		if (player === player1) {
			return 0;
		} else if (player === player2) {
			return 1;
		} else {
			return null;
		}
	}
	
	PlayerStatus? playerState(PlayerImpl player) {
		if (exists index = playerIndex(player)) {
			return playerStates[index];
		} else {
			return null;
		}
		
	}
	
	PlayerImpl? opponent(PlayerImpl player)  {
		if (player === player1) {
			return player2;
		} else if (player === player2) {
			return player1;
		} else {
			return null;
		}
	}
	
	shared Boolean end(PlayerImpl player) {
		if (winner exists) {
			return false;
		} else if (playerIndex(player) exists) {
			if (exists currentGame = game) {
				world.publish(SurrenderGameMessage(player, this));
				winner = opponent(player);
				game = null;
			}
			
			if (table.removeMatch(this)) {
				world.publish(EndedMatchMessage(player, this));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	Boolean markReady(PlayerImpl player) {
		if (game exists || winner exists) {
			return false;
		} else if (remainingJoinTime.milliseconds < 0) {
			if (!playerStates[0].ready) {
				player1.leaveMatch();
			}
			if (!playerStates[1].ready) {
				player2.leaveMatch();
			}
			return false;
		} else if (exists state = playerState(player)) {
			state.ready = true;
			return true;
		} else {
			return false;
		}
	}
	
	Boolean canStartGame() => playerStates[0].ready && playerStates[1].ready;
	
	void forwardGameMessage(GameMessage message) {
		if (gameId != message.gameId) {
			return;
		} else if (message.playerId == player1.id) {
			world.publish(AdaptedGameMessage(player1, this, message));
		} else if (message.playerId == player2.id) {
			world.publish(AdaptedGameMessage(player2, this, message));
		}
	}
	
	shared Boolean startGame(PlayerImpl player) {
		if (markReady(player)) {
			world.publish(StartGameMessage(player, this));
			if (canStartGame()) {
				value currentGame = makeGame(player1.id, player2.id, gameId, forwardGameMessage);
				game = currentGame;
				currentGame.initialRoll(diceRoller.roll());
				return true;
			}
		}
		return false;
	}
}

class MatchTest() {
	
	value match = MatchImpl(PlayerImpl("player1"), PlayerImpl("player2"), TableImpl(0, "room"));
	
	value messageList = ArrayList<ApplicationMessage>();
	world.messageListener = messageList.add;
	
	test
	shared void newMatchHasRemainingJoinTime() {
		assert (match.remainingJoinTime.milliseconds > 0);
	}
	
	test
	shared void newMatchHasNoGame() {
		value result = match.game exists;
		assert (!result);
	}
	
	test
	shared void newMatchHasNoWinner() {
		value result = match.winner exists;
		assert (!result);
	}
	
	test
	shared void startGameWithThirdPlayer() {
		value result = match.startGame(PlayerImpl("player3"));
		assert (!result);
		assert (messageList.count((ApplicationMessage element) => element is StartGameMessage) == 0);
	}
	
	test
	shared void startGameWithTwoPlayers() {
		value result1 = match.startGame(match.player1);
		assert (!result1);
		value result2 = match.startGame(match.player2);
		assert (result2);
		assert (messageList.count((ApplicationMessage element) => element is StartGameMessage) == 2);
	}
	
	test
	shared void startGameWithOnlyOnePlayer() {
		value result = match.startGame(match.player1);
		assert (!result);
		assert (messageList.count((ApplicationMessage element) => element is StartGameMessage) == 1);
	}
	
}