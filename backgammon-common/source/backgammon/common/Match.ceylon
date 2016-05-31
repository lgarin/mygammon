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
shared interface Match {
	shared formal Duration remainingJoinTime;
	
	shared formal Player player1;
	shared formal Boolean player1Ready;
	
	shared formal Player player2;
	shared formal Boolean player2Ready;
	
	shared formal Table table;
	
	shared formal Game? game;
}

class MatchImpl(shared actual PlayerImpl player1, shared actual PlayerImpl player2, shared actual TableImpl table) satisfies Match {
	
	shared actual variable Game? game = null;
	
	shared Instant creationTime = now();
	
	value diceRoller = DiceRoller();
	
	value gameId = "``table.roomId``-``table.index``-``creationTime.millisecondsOfEpoch``";
	
	shared actual Duration remainingJoinTime => Duration(creationTime.durationTo(now()).milliseconds - world.maximumGameJoinTime.milliseconds);

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
	
	shared actual Boolean player1Ready => playerStates[0].ready;
	
	shared actual Boolean player2Ready => playerStates[1].ready;
	
	shared Boolean removePlayer(PlayerImpl player) {
		if (playerIndex(player) exists) {
			if (exists currentGame = game) {
				// TODO should do it only with a confirmation
				world.publish(SurrenderGameMessage(player, this));
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
		if (game exists) {
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
				// TODO delay ???
				currentGame.initialRoll(diceRoller.roll());
				return true;
			}
		}
		return false;
	}
}