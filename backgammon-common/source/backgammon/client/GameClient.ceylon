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
	TableStateResponseMessage,
	RoomResponseMessage,
	PlayerInfo,
	PlayerId,
	MatchState,
	GameStateRequestMessage
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

import ceylon.interop.browser {
	window
}
import ceylon.time {

	Instant
}
shared class GameClient(Anything(InboundGameMessage) messageBroadcaster) {
	
	variable PlayerInfo? playerInfo = null;
	
	value playerId {
		if (exists id = playerInfo?.id) {
			return PlayerId(id);
		} else {
			return null;
		}
	}
	
	value game = Game();
	value gui = GameGui(window.document);
	
	variable Integer? initialDiceValue = null;
	variable CheckerColor? playerColor = null;
	
	function showInitialRoll(InitialRollMessage message) {
		if (exists currentPlayerId = playerId, message.playerId == currentPlayerId) {
			// TODO check return value
			game.initialRoll(message.roll, message.maxDuration);
			initialDiceValue = message.diceValue;
			playerColor = message.playerColor;
			// TODO start timer
		} else {
			gui.showDiceValues(message.playerColor.oppositeColor, message.diceValue, null);
		}
		return true;
	}
	
	function showTurnStart(StartTurnMessage message) {
		if (game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo)) {
			gui.showDiceValues(message.playerColor.oppositeColor, null, null);
			gui.showDiceValues(message.playerColor, message.roll.firstValue, message.roll.secondValue);
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration), false);
			gui.showPlayerMessage(message.playerColor.oppositeColor, "Waiting...", false); // TODO start timer			return true;
		} else {
			return false;
		}
	}
	
	void restoreBoardState(GameState state) {
		game.state = state;
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
		gui.redrawCheckers(black, state.blackCheckerCounts);
		gui.redrawCheckers(white, state.whiteCheckerCounts);
		gui.showCurrentPlayer(game.currentColor);
		
		
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
	
	shared Boolean handleMessage(OutboundGameMessage message) {
		
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
			// TODO restore state
			//messageBroadcaster(UndoMovesMessage(matchId, playerId));
			return false;
		}
		case (is DesynchronizedMessage) {
			restoreBoardState(message.state);
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
			restoreBoardState(message.state);
			return true;
		}
		case (is GameActionResponseMessage) {
			return false;
		}
	}
	
	void showMatchBegin(MatchState match) {
		gui.showPlayerMessage(player1Color, match.playerReady(player1Color) then "Ready" else "Play?", false);
		gui.showPlayerMessage(player2Color, match.playerReady(player2Color) then "Ready" else "Play?", false);
		if (exists currentPlayerId = playerId, match.mustStartMatch(currentPlayerId)) {
			gui.showSubmitButton("Start");
		} else {
			gui.hideSubmitButton();
		}
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	void showFirstPlayer(PlayerInfo currentPlayer) {
		gui.showPlayerInfo(player1Color, currentPlayer.name, currentPlayer.pictureUrl);
		gui.showPlayerMessage(player1Color, "Joined", false);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	void showEmptyTable() {
		gui.showPlayerInfo(player1Color, null, null);
		gui.showPlayerMessage(player1Color, "Waiting...", true);
		gui.showPlayerInfo(player2Color, null, null);
		gui.showPlayerMessage(player2Color, "Waiting...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);
	}
	
	void showResumingGame() {
		gui.showPlayerMessage(player1Color, "Loading...", true);
		gui.showPlayerMessage(player2Color, "Loading...", true);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton(null);	}

	void handleTableStateResponseMessage(TableStateResponseMessage message) {
		gui.showEmptyGame();
		
		if (exists match = message.match, exists currentPlayerId = playerId) {
			gui.showPlayerInfo(player1Color, match.player1.name, match.player1.pictureUrl);
			gui.showPlayerInfo(player2Color, match.player2.name, match.player2.pictureUrl);
			if (match.gameStarted) {
				showResumingGame();
				messageBroadcaster(GameStateRequestMessage(match.id, currentPlayerId));
			} else if (match.gameEnded) {
				showWin(match.winnerColor);
			} else {
				showMatchBegin(match);
			}
		} else if (exists currentPlayer = playerInfo) {
			showFirstPlayer(currentPlayer);
		} else {
			showEmptyTable();
		}
	}
	
	shared void handleTimerEvent(Instant time) {
		// TODO implement
	}
	
	shared Boolean handleRoomMessage(RoomResponseMessage message) {
		if (!message.success) {
			return false;
		}
		switch (message)
		case (is TableStateResponseMessage) {
			handleTableStateResponseMessage(message);
			return true;
		}
		else {
			// TODO handle all messages
			return false;
		}
		
	}
}