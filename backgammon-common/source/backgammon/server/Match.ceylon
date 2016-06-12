import ceylon.time {

	Duration,
	Instant,
	now
}
import backgammon.game {
	GameConfiguration
}
import ceylon.test {

	test
}
import ceylon.collection {

	ArrayList
}

shared final class MatchId(shared TableId tableId, Instant creationTime) extends StringIdentifier("``tableId``-game-``creationTime.millisecondsOfEpoch``") {}

class Match(shared Player player1, shared Player player2, shared Table table) {
	
	shared variable GameServer? game = null;
	
	shared variable PlayerId? winnerId = null;
	
	Instant creationTime = now();
	
	shared MatchId id = MatchId(table.id, creationTime);
	
	shared Duration remainingJoinTime => Duration(world.maximumGameJoinTime.milliseconds - creationTime.durationTo(now()).milliseconds);

	class PlayerStatus() {
		shared variable Boolean ready = false;
	}
	
	[PlayerStatus, PlayerStatus] playerStates = [PlayerStatus(), PlayerStatus()];
	
	Integer? playerIndex(Player player) {
		if (player === player1) {
			return 0;
		} else if (player === player2) {
			return 1;
		} else {
			return null;
		}
	}
	
	PlayerStatus? playerState(Player player) {
		if (exists index = playerIndex(player)) {
			return playerStates[index];
		} else {
			return null;
		}
		
	}
	
	shared Boolean end(Player player) {
		if (winnerId exists) {
			return false;
		} else if (playerIndex(player) exists) {
			if (exists currentGame = game) {
				assert (currentGame.quitGame(player.id));
				game = null;
			}
			
			if (table.removeMatch(this)) {
				world.publish(LeaftMatchMessage(player.id, id));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	Boolean markReady(Player player) {
		if (game exists || winnerId exists) {
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
		if (id == message.matchId) {
			if (is GameWonMessage message) {
				winnerId = message.playerId;
			} else if (is GameEndedMessage message) {
				table.removeMatch(this);
			}
			world.publish(message);
		}
		
	}
	
	shared Boolean startGame(Player player) {
		if (markReady(player)) {
			world.publish(StartGameMessage(player.id, id));
			if (canStartGame()) {
				value currentGame = GameServer(player1.id, player2.id, id, GameConfiguration(world.maximumTurnTime), forwardGameMessage);
				game = currentGame;
				return currentGame.sendInitialRoll();
			}
		}
		return false;
	}
}

class MatchTest() {
	
	value match = Match(Player("player1"), Player("player2"), Table(0, RoomId("room")));
	
	value messageList = ArrayList<TableMessage>();
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
		value result = match.winnerId exists;
		assert (!result);
	}
	
	test
	shared void startGameWithThirdPlayer() {
		value result = match.startGame(Player("player3"));
		assert (!result);
		assert (messageList.count((TableMessage element) => element is StartGameMessage) == 0);
	}
	
	test
	shared void startGameWithTwoPlayers() {
		value result1 = match.startGame(match.player1);
		assert (!result1);
		value result2 = match.startGame(match.player2);
		assert (result2);
		assert (messageList.count((TableMessage element) => element is StartGameMessage) == 2);
	}
	
	test
	shared void startGameWithOnlyOnePlayer() {
		value result = match.startGame(match.player1);
		assert (!result);
		assert (messageList.count((TableMessage element) => element is StartGameMessage) == 1);
	}
	
}