import backgammon.common {
	InboundGameMessage,
	OutboundGameMessage,
	InitialRollMessage,
	PlayedMoveMessage,
	StartTurnMessage,
	UndoneMovesMessage,
	InvalidMoveMessage,
	DesynchronizedMessage,
	NotYourTurnMessage,
	GameWonMessage,
	GameEndedMessage,
	GameStateResponseMessage,
	GameActionResponseMessage,
	PlayerId,
	MatchId,
	UndoMovesMessage
}
import backgammon.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color,
	GameState
}

import ceylon.time {
	Instant
}
shared class GameClient(PlayerId playerId, MatchId matchId, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	value game = Game();
	
	variable Integer? initialDiceValue = null;
	variable CheckerColor? playerColor = null;
	
	function showInitialRoll(InitialRollMessage message) {
		if (message.playerId == playerId) {
			// TODO check return value
			game.initialRoll(message.roll, message.maxDuration);
			initialDiceValue = message.diceValue;
			playerColor = message.playerColor;
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration), true);
		} else {
			gui.showDiceValues(message.playerColor.oppositeColor, message.diceValue, null);
		}
		return true;
	}
	
	function showTurnStart(StartTurnMessage message) {
		if (game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo)) {
			gui.showDiceValues(message.playerColor.oppositeColor, null, null);
			gui.showDiceValues(message.playerColor, message.roll.firstValue, message.roll.secondValue);
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration), true);
			gui.showPlayerMessage(message.playerColor.oppositeColor, "Waiting...", false);			return true;
		} else {
			return false;
		}
	}
	
	void showGameState(GameState state) {
		if (exists currentColor = state.currentColor, exists currentRoll = state.currentRoll) {
			gui.showDiceValues(currentColor, currentRoll.firstValue, currentRoll.secondValue);
			gui.showDiceValues(currentColor.oppositeColor, null, null);
		} else if (exists currentRoll = state.currentRoll) {
			gui.showDiceValues(black, currentRoll.getValue(black), null);
			gui.showDiceValues(white, currentRoll.getValue(white), null);
		} else {
			gui.showDiceValues(black, null, null);
			gui.showDiceValues(white, null, null);
		}
		gui.redrawCheckers(black, state.blackCheckerCounts);
		gui.redrawCheckers(white, state.whiteCheckerCounts);
		gui.showCurrentPlayer(state.currentColor);
		if (exists currentColor = state.currentColor) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(state.remainingTime()), true);
			gui.showPlayerMessage(currentColor.oppositeColor, "Waiting...", true);
			if (exists color = playerColor, currentColor == color) {
				gui.showSubmitButton(null);
			} else {
				gui.hideSubmitButton();
			}
		} else { 
			
			if (state.mustRollDice(black)) {
				gui.showPlayerMessage(black, "Ready", false);
			} else {
				gui.showPlayerMessage(black, "Roll?", true);
			}
			if (state.mustRollDice(white)) {
				gui.showPlayerMessage(white, "Ready", false);
			}  else {
				gui.showPlayerMessage(white, "Roll?", false);
			}
			
			if (exists color = playerColor, state.mustRollDice(color)) {
				gui.showSubmitButton("Roll");
			} else {
				gui.hideSubmitButton();
			}
		}
		if (exists color = playerColor, state.canUndoMoves(color)) {
			gui.showUndoButton(null);
		} else {
			gui.hideUndoButton();
		}
	}
	
	function showPlayedMove(PlayedMoveMessage message) {
		if (game.moveChecker(message.playerColor, message.move.sourcePosition, message.move.targetPosition)) {
			gui.redrawCheckers(message.playerColor, game.checkerCounts(message.playerColor));
			return true;
		} else {
			return false;
		}
	}
	
	function showUndoneMoves(UndoneMovesMessage message) {
		if (game.undoTurnMoves(message.playerColor)) {
			gui.redrawCheckers(message.playerColor, game.checkerCounts(message.playerColor));
			return true;
		} else {
			return false;
		}
	}
	
	void showWin(CheckerColor? color) {
		if (exists currentColor = color) {
			gui.showPlayerMessage(currentColor, "Winner", false);
			gui.showPlayerMessage(currentColor.oppositeColor, "", false);
		} else {
			gui.showPlayerMessage(player1Color, "Tie", false);
			gui.showPlayerMessage(player2Color, "Tie", false);
		}
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	shared Boolean handleGameMessage(OutboundGameMessage message) {
		
		switch (message) 
		case (is InitialRollMessage) {
			return showInitialRoll(message);
		}
		case (is StartTurnMessage) {
			return showTurnStart(message);
		}
		case (is PlayedMoveMessage) {
			return showPlayedMove(message);
		}
		case (is UndoneMovesMessage) {
			return showUndoneMoves(message);
		}
		case (is InvalidMoveMessage) {
			messageBroadcaster(UndoMovesMessage(matchId, playerId));
			return true;
		}
		case (is DesynchronizedMessage) {
			game.state = message.state;
			showGameState(message.state);
			return true;
		}
		case (is NotYourTurnMessage) {
			return false;
		}
		case (is GameWonMessage) {
			showWin(message.playerColor);
			return true;
		}
		case (is GameEndedMessage) {
			gui.hideSubmitButton();
			gui.hideUndoButton();
			return true;
		}
		case (is GameStateResponseMessage) {
			game.state = message.state;
			showGameState(message.state);
			return true;
		}
		case (is GameActionResponseMessage) {
			return message.success;
		}
	}
	shared void handleTimerEvent(Instant time) {
		// TODO implement
	}
	
	shared void showState() {
		showGameState(game.state);
	}
}