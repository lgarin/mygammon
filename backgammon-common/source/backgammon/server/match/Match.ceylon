import ceylon.time {

	Duration,
	Instant,
	now
}

import ceylon.test {

	test
}
import ceylon.collection {

	ArrayList
}

import backgammon.common {

	StartMatchMessage,
	LeaftMatchMessage,
	TableMessage,
	EndGameMessage,
	GameWonMessage,
	GameMessage,
	StartGameMessage,
	GameEndedMessage,
	PlayerId,
	MatchId,
	RoomId,
	PlayerInfo
}


class Match(shared Player player1, shared Player player2, shared Table table) {
	
	variable PlayerId? winnerId = null;
	
	Instant creationTime = now();
	
	shared MatchId id = MatchId(table.id, creationTime);
	
	shared Duration remainingJoinTime => Duration(table.maxMatchJoinTime.milliseconds - creationTime.durationTo(now()).milliseconds);

	class PlayerStatus() {
		shared variable Boolean ready = false;
	}
	
	value playerStates = [PlayerStatus(), PlayerStatus()];
	
	function playerIndex(Player player) {
		if (player === player1) {
			return 0;
		} else if (player === player2) {
			return 1;
		} else {
			return null;
		}
	}
	
	function playerState(Player player) {
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
			if (isStarted) {
				playerStates[0].ready = false;
				playerStates[1].ready = false;
				table.send(EndGameMessage(id, player.id));
			}
			
			if (table.removeMatch(this)) {
				table.publish(LeaftMatchMessage(player.id, id));
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	function markReady(Player player) {
		if (isStarted || winnerId exists) {
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
	
	function canStartGame() => playerStates[0].ready && playerStates[1].ready;
	
	shared Boolean isStarted => canStartGame();
	
	shared Boolean processGameMessage(GameMessage message) {
		if (id == message.matchId) {
			if (is GameWonMessage message) {
				winnerId = message.playerId;
			} else if (is GameEndedMessage message) {
				table.removeMatch(this);
			}
			return true;
		} else {
			return false;
		}
		
	}
	
	shared Boolean startGame(Player player) {
		if (markReady(player)) {
			table.publish(StartMatchMessage(player.id, id));
			if (canStartGame()) {
				table.send(StartGameMessage(id, player1.id, player2.id));
				return true;
			}
		}
		return false;
	}
}

class MatchTest() {
	
	function makePlayer(String id) => Player(PlayerInfo(id, id, null), null);
	
	
	value messageList = ArrayList<TableMessage>();
	value match = Match(makePlayer("player1"), makePlayer("player2"), Table(0, RoomId("room"), Duration(1000), messageList.add));
	
	test
	shared void newMatchHasRemainingJoinTime() {
		assert (match.remainingJoinTime.milliseconds > 0);
	}
	
	test
	shared void newMatchIsNotStarted() {
		assert (!match.isStarted);
	}
	
	test
	shared void startGameWithThirdPlayer() {
		value result = match.startGame(makePlayer("player3"));
		assert (!result);
		assert (messageList.count((TableMessage element) => element is StartMatchMessage) == 0);
	}
	
	test
	shared void startGameWithTwoPlayers() {
		value result1 = match.startGame(match.player1);
		assert (!result1);
		value result2 = match.startGame(match.player2);
		assert (result2);
		assert (messageList.count((TableMessage element) => element is StartMatchMessage) == 2);
	}
	
	test
	shared void startGameWithOnlyOnePlayer() {
		value result = match.startGame(match.player1);
		assert (!result);
		assert (messageList.count((TableMessage element) => element is StartMatchMessage) == 1);
	}
	
}