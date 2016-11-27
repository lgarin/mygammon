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
	GameState
}
import ceylon.time {
	now
}

class GameTest() {
	
	value game = Game();
	
	test
	shared void checkInitialGame() {
		assert (game.currentColor is Null);
		assert (!game.isCurrentColor(black));
		assert (!game.isCurrentColor(white));
		assert (game.currentRoll is Null);
		assert ([0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0] == game.board.checkerCounts(black));
		assert ([0, 0, 0, 0, 0, 0, 5, 0, 3, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0] == game.board.checkerCounts(white));
		assert (!game.mustRollDice(black));
		assert (!game.mustRollDice(white));
		assert (!game.mustMakeMove(black));
		assert (!game.canUndoMoves(white));
		assert (!game.canUndoMoves(black));
		assert (game.remainingTime(now()) is Null);
		assert (!game.timedOut(now()));
	}
	
	test
	shared void checkInitialState() {
		value state = game.state;
		assert (state.currentColor is Null);
		assert (state.currentRoll is Null);
		assert (state.blackCheckerCounts.sequence() == [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0]);
		assert (state.whiteCheckerCounts.sequence() == [0, 0, 0, 0, 0, 0, 5, 0, 3, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0]);
		assert (!state.blackReady);
		assert (!state.whiteReady);
		assert (state.remainingUndo == 0);
		assert (state.currentMoves.empty);
		assert (state.remainingTime is Null);
	}
	
	test
	shared void computeInitalBlackMoves() {
		value moves = game.computeNextMoves(black, DiceRoll(3, 1));
		assert (moves.contains(GameMoveInfo(1, 2, 1, false)));
		assert (moves.contains(GameMoveInfo(1, 4, 3, false)));
		assert (moves.contains(GameMoveInfo(12, 15, 3, false)));
		assert (moves.contains(GameMoveInfo(17, 18, 1, false)));
		assert (moves.contains(GameMoveInfo(17, 20, 3, false)));
		assert (moves.contains(GameMoveInfo(19, 20, 1, false)));
		assert (moves.contains(GameMoveInfo(19, 22, 3, false)));
		assert (moves.size == 7);
	}
	
	test
	shared void computeInitalWhiteMoves() {
		value moves = game.computeNextMoves(white, DiceRoll(1, 5));
		assert (moves.contains(GameMoveInfo(24, 23, 1, false)));
		assert (moves.contains(GameMoveInfo(13, 8, 5, false)));
		assert (moves.contains(GameMoveInfo(8, 7, 1, false)));
		assert (moves.contains(GameMoveInfo(8, 3, 5, false)));
		assert (moves.contains(GameMoveInfo(6, 5, 1, false)));
		assert (moves.size == 5);
	}
	
	test
	shared void computeAllMoves() {
		value moves = game.computeAllMoves(white, DiceRoll(1, 5), 24).keys;
		assert (moves.contains(GameMove(24, 23)));
		assert (moves.contains(GameMove(24, 18)));
		assert (moves.size == 2);
	}
	
	test
	shared void computeBestMoveSequence() {
		value sequence = game.computeBestMoveSequence(white, DiceRoll(1, 5), 24, 18);
		assert (sequence == [GameMoveInfo(24, 23, 1, false), GameMoveInfo(23, 18, 5, false)]);
	}
	
	test
	shared void computeImpossibleMoveSequence() {
		value sequence = game.computeBestMoveSequence(white, DiceRoll(1, 5), 24, 19);
		assert (sequence == []);
	}
	
	test
	shared void computeBestMoveSequenceFromGraveyard() {
		value state = GameState();
		state.blackCheckerCounts = {1, 0};
		state.whiteCheckerCounts = {0, 0, 1};
		game.state = state;
		
		value sequence = game.computeBestMoveSequence(black, DiceRoll(2, 1), 0, 3);
		assert (sequence == [GameMoveInfo(0, 2, 2, true), GameMoveInfo(2, 3, 1, false)]);
		
		value sequence2 = game.computeBestMoveSequence(black, DiceRoll(2, 1), 0, 1);
		assert (sequence2 == [GameMoveInfo(0, 1, 1, false)]);
	}
	
	test
	shared void computeBestMoveSequenceFromMidpoint() {
		value state = GameState();
		state.blackCheckerCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1};
		state.whiteCheckerCounts = {};
		game.state = state;
		
		value sequence = game.computeBestMoveSequence(black, DiceRoll(4, 5), 12, 16);
		assert (sequence == [GameMoveInfo(12, 16, 4, false)]);
	}
}