import ceylon.test {
	test
}
import backgammon.shared.game {
	GameMoveInfo,
	DiceRoll,
	Game,
	white,
	black,
	GameMove,
	GameState,
	whiteStartPosition,
	whiteGraveyardPosition,
	blackGraveyardPosition,
	blackStartPosition
}
import ceylon.time {
	now,
	Instant,
	Duration
}

class GameTest() {
	
	value timestamp = Instant(0);
	value game = Game(timestamp);
	
	test
	shared void checkInitialGame() {
		assert (game.currentColor is Null);
		assert (!game.isCurrentColor(black));
		assert (!game.isCurrentColor(white));
		assert (game.currentRoll is Null);
		assert ([12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] == game.checkerCounts(black));
		assert ([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12] == game.checkerCounts(white));
		assert (!game.mustRollDice(black));
		assert (!game.mustRollDice(white));
		assert (!game.canUndoMoves(white));
		assert (!game.canUndoMoves(black));
		assert (game.remainingTime(now()) is Null);
		assert (!game.timedOut(now()));
	}
	
	test
	shared void checkInitialState() {
		value state = game.buildState(timestamp);
		assert (state.currentColor is Null);
		assert (state.currentRoll is Null);
		assert (state.blackCheckerCounts.sequence() == [12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
		assert (state.whiteCheckerCounts.sequence() == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12]);
		assert (!state.blackReady);
		assert (!state.whiteReady);
		assert (state.remainingUndo == 0);
		assert (state.currentMoves.empty);
		assert (state.remainingTime is Null);
	}
	
	test
	shared void computeInitalBlackMoves() {
		value moves = game.computeNextMoves(black, DiceRoll(3, 1));
		assert (moves.contains(GameMove(blackStartPosition, blackGraveyardPosition + 1)));
		assert (moves.contains(GameMove(blackStartPosition, blackGraveyardPosition + 3)));
		assert (moves.size == 2);
	}
	
	test
	shared void computeInitalWhiteMoves() {
		value moves = game.computeNextMoves(white, DiceRoll(1, 5));
		assert (moves.contains(GameMove(whiteStartPosition, whiteGraveyardPosition - 1)));
		assert (moves.contains(GameMove(whiteStartPosition, whiteGraveyardPosition - 5)));
		assert (moves.size == 2);
	}
	
	test
	shared void computeAllMoves() {
		value moves = game.computeAllMoves(white, DiceRoll(1, 5), whiteStartPosition).keys;
		assert (moves.contains(GameMove(whiteStartPosition, whiteGraveyardPosition - 1)));
		assert (moves.contains(GameMove(whiteStartPosition, whiteGraveyardPosition - 5)));
		assert (moves.contains(GameMove(whiteStartPosition, whiteGraveyardPosition - 6)));
		assert (moves.size == 3);
	}
	
	test
	shared void computeBestMoveSequence() {
		value sequence = game.computeBestMoveSequence(white, DiceRoll(1, 5), whiteStartPosition, whiteGraveyardPosition - 6);
		assert (sequence == [GameMoveInfo(whiteStartPosition, whiteGraveyardPosition - 1, 1, false), GameMoveInfo(whiteGraveyardPosition - 1, whiteGraveyardPosition - 6, 5, false)]);
	}
	
	test
	shared void computeImpossibleMoveSequence() {
		value sequence = game.computeBestMoveSequence(white, DiceRoll(1, 5), 24, 19);
		assert (sequence == []);
	}
	
	test
	shared void computeBestMoveSequenceFromGraveyard() {
		value state = GameState();
		state.blackCheckerCounts = [0, 1, 0, 0];
		state.whiteCheckerCounts = [0, 0, 0, 1];
		game.resetState(state, timestamp);
		
		value sequence = game.computeBestMoveSequence(black, DiceRoll(2, 1), blackGraveyardPosition, blackGraveyardPosition + 3);
		assert (sequence == [GameMoveInfo(blackGraveyardPosition, blackGraveyardPosition+2, 2, true), GameMoveInfo(blackGraveyardPosition+2, blackGraveyardPosition+3, 1, false)]);
		
		value sequence2 = game.computeBestMoveSequence(black, DiceRoll(2, 1), blackGraveyardPosition, blackGraveyardPosition+1);
		assert (sequence2 == [GameMoveInfo(blackGraveyardPosition, blackGraveyardPosition+1, 1, false)]);
	}
	
	test
	shared void computeBestMoveSequenceFromMidpoint() {
		value state = GameState();
		state.blackCheckerCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];
		state.whiteCheckerCounts = [];
		game.resetState(state, timestamp);
		
		value sequence = game.computeBestMoveSequence(black, DiceRoll(4, 5), 12, 16);
		assert (sequence == [GameMoveInfo(12, 16, 4, false)]);
	}
	
	test
	shared void undoFirstTurn() {
		game.initialRoll(DiceRoll(2, 1), now(), Duration(100));
		game.begin(black, now(), 1);
		game.begin(white, now(), 1);
		game.beginTurn(black, DiceRoll(2, 1), now(), Duration(100), 1);
		game.moveChecker(black, blackStartPosition, blackStartPosition + 2);
		game.endTurn(black, now());
		game.beginTurn(white, DiceRoll(1, 1), now(), Duration(100), 1);
		game.undoTurn(white, now());
		assert ([12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] == game.checkerCounts(black));
		assert ([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12] == game.checkerCounts(white));
		assert (1 == game.remainingJoker(black));
		assert (0 == game.remainingJoker(white));
		assert (true == game.isCurrentColor(black));
		assert (false == game.canUndoTurn(black));
	}
}