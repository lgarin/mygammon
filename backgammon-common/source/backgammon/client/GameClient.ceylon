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
	UndoMovesMessage,
	PlayerReadyMessage,
	EndTurnMessage,
	CheckTimeoutMessage
}
import backgammon.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color
}

import ceylon.time {
	Instant,
	now
}
shared class GameClient(PlayerId playerId, MatchId matchId, CheckerColor? playerColor, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	value game = Game();
	
	variable Integer? initialDiceValue = null;
	
	function showInitialRoll(InitialRollMessage message) {
		gui.showCurrentPlayer(null);
		if (message.playerId == playerId) {
			if (game.initialRoll(message.roll, message.maxDuration)) {
				initialDiceValue = message.diceValue;
				gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration), true);
				return true;
			} else {
				return false;
			}
		} else {
			if (game.begin(message.playerColor)) {
				gui.showDiceValues(message.playerColor, message.diceValue, null);
				return true;
			} else {
				return false;
			}
		}
	}
	
	function showTurnStart(StartTurnMessage message) {
		gui.showCurrentPlayer(message.playerColor);
		if (game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo)) {
			gui.showDiceValues(message.playerColor.oppositeColor, null, null);
			gui.showDiceValues(message.playerColor, message.roll.firstValue, message.roll.secondValue);
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration), true);
			gui.showPlayerMessage(message.playerColor.oppositeColor, "Waiting...", false);
			return true;
		} else {
			return false;
		}
	}
	
	void showGameState() {
		value currentTime = now();
		gui.showCurrentPlayer(game.currentColor);
		if (exists currentColor = game.currentColor, exists currentRoll = game.currentRoll) {
			gui.showDiceValues(currentColor, currentRoll.firstValue, currentRoll.secondValue);
			gui.showDiceValues(currentColor.oppositeColor, null, null);
		} else if (exists currentRoll = game.currentRoll) {
			gui.showDiceValues(black, currentRoll.getValue(black), null);
			gui.showDiceValues(white, currentRoll.getValue(white), null);
		} else {
			gui.showDiceValues(black, null, null);
			gui.showDiceValues(white, null, null);
		}
		gui.redrawCheckers(game.board);
		gui.showCurrentPlayer(game.currentColor);
		if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(currentTime)) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime), true);
			gui.showPlayerMessage(currentColor.oppositeColor, "Waiting...", true);
			if (exists color = playerColor, currentColor == color) {
				gui.showSubmitButton(null);
			} else {
				gui.hideSubmitButton();
			}
		} else { 
			
			if (game.mustRollDice(black), exists remainingTime = game.remainingTime(currentTime)) {
				gui.showPlayerMessage(black, gui.formatPeriod(remainingTime), true);
			} else {
				gui.showPlayerMessage(black, "Ready", false);
			}
			if (game.mustRollDice(white), exists remainingTime = game.remainingTime(currentTime)) {
				gui.showPlayerMessage(white, gui.formatPeriod(remainingTime), true);
			}  else {
				gui.showPlayerMessage(white, "Ready", false);
			}
			
			if (exists color = playerColor, game.mustRollDice(color)) {
				gui.showSubmitButton("Roll");
			} else {
				gui.hideSubmitButton();
			}
		}
		if (exists color = playerColor, game.canUndoMoves(color)) {
			gui.showUndoButton(null);
		} else {
			gui.hideUndoButton();
		}
	}
	
	function showPlayedMove(PlayedMoveMessage message) {
		if (game.moveChecker(message.playerColor, message.sourcePosition, message.targetPosition)) {
			gui.redrawCheckers(game.board);
			return true;
		} else {
			return false;
		}
	}
	
	function showUndoneMoves(UndoneMovesMessage message) {
		if (game.undoTurnMoves(message.playerColor)) {
			gui.redrawCheckers(game.board);
			return true;
		} else {
			return false;
		}
	}
	
	void showWin(CheckerColor? color) {
		gui.showCurrentPlayer(color);
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
			showGameState();
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
			game.end();
			gui.hideSubmitButton();
			gui.hideUndoButton();
			return true;
		}
		case (is GameStateResponseMessage) {
			game.state = message.state;
			showGameState();
			return true;
		}
		case (is GameActionResponseMessage) {
			return message.success;
		}
	}
	
	shared Boolean handleTimerEvent(Instant time) {
		if (game.timedOut(time)) {
			gui.hideSubmitButton();
			gui.hideUndoButton();
			if (exists currentColor = game.currentColor) {
				gui.showPlayerMessage(currentColor, "Time out", false);
			} else {
				gui.showPlayerMessage(player1Color, "Time out", true);
				gui.showPlayerMessage(player2Color, "Time out", true);
			}
			messageBroadcaster(CheckTimeoutMessage(matchId, playerId));
			return true;
		} else if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(time)) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime), true);
			return true;
		} else if (game.mustRollDice(player1Color) || game.mustRollDice(player2Color)) {
			if (game.mustRollDice(player1Color), exists remainingTime = game.remainingTime(time)) {
				gui.showPlayerMessage(player1Color, gui.formatPeriod(remainingTime), true);
			}
			if (game.mustRollDice(player2Color), exists remainingTime = game.remainingTime(time)) {
				gui.showPlayerMessage(player2Color, gui.formatPeriod(remainingTime), true);
			}
			return true;
		} else {
			return true;
		}
	}
	
	shared void showState() {
		showGameState();
	}
	
	shared Boolean handleSubmitEvent() {
		if (exists color = playerColor, exists diceValue = initialDiceValue, game.mustRollDice(color)) {
			if (game.begin(color)) {
				gui.showDiceValues(color, diceValue, null);
				gui.hideSubmitButton();
				messageBroadcaster(PlayerReadyMessage(matchId, playerId));
				return true;
			} else {
				return false;
			}
		} else if (exists color = playerColor, game.mustMakeMove(color)) {
			gui.hidePossibleMoves();
			gui.deselectAllCheckers();
			gui.hideSubmitButton();
			messageBroadcaster(EndTurnMessage(matchId, playerId));
			return true;
		} else {
			return false;
		}
	}
}