import ceylon.test {
	test
}
import backgammon.shared.game {
	GameMove,
	DiceRoll,
	Game,
	white,
	black
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
		assert (state.blackCheckerCounts == [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0]);
		assert (state.whiteCheckerCounts == [0, 0, 0, 0, 0, 0, 5, 0, 3, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0]);
		assert (!state.blackReady);
		assert (!state.whiteReady);
		assert (state.remainingUndo == 0);
		assert (state.currentMoves.empty);
		assert (state.remainingTime is Null);
	}
	
	test
	shared void computeInitalBlackMoves() {
		value moves = game.computeAvailableMoves(black, DiceRoll(3, 1));
		assert (moves.contains(GameMove(1, 2, 1, false)));
		assert (moves.contains(GameMove(1, 4, 3, false)));
		assert (moves.contains(GameMove(12, 15, 3, false)));
		assert (moves.contains(GameMove(17, 18, 1, false)));
		assert (moves.contains(GameMove(17, 20, 3, false)));
		assert (moves.contains(GameMove(19, 20, 1, false)));
		assert (moves.contains(GameMove(19, 22, 3, false)));
		assert (moves.size == 7);
	}
	
	test
	shared void computeInitalWhiteMoves() {
		value moves = game.computeAvailableMoves(white, DiceRoll(1, 5));
		assert (moves.contains(GameMove(24, 23, 1, false)));
		assert (moves.contains(GameMove(13, 8, 5, false)));
		assert (moves.contains(GameMove(8, 7, 1, false)));
		assert (moves.contains(GameMove(8, 3, 5, false)));
		assert (moves.contains(GameMove(6, 5, 1, false)));
		assert (moves.size == 5);
	}
}