import backgammon.browser {
	HTMLElement
}
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
	PlayerReadyMessage,
	EndTurnMessage,
	MakeMoveMessage,
	TurnTimedOutMessage
}
import backgammon.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color,
	GameMove
}

import ceylon.time {
	Instant,
	now,
	Duration
}
shared class GameClient(PlayerId playerId, MatchId matchId, CheckerColor? playerColor, GameGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	// TODO should be part of configuration
	value initialRollDelay = Duration(2000);
			
	value game = Game();
	
	final class DelayedGameMessage(shared InboundGameMessage message, Duration delay) {
		value sendTime = now().plus(delay);
		
		shared Boolean mustSend(Instant time) {
			return sendTime <= time || game.timedOut(time);
		}
	}
	
	variable [DelayedGameMessage*] delayedMessage = [];
	
	function showInitialRoll(InitialRollMessage message) {
		gui.showCurrentPlayer(null);
		if (message.playerId == playerId) {
			if (game.initialRoll(message.roll, message.maxDuration)) {
				game.begin(message.playerColor.oppositeColor);
				gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, "Timeout"), true);
				gui.showCurrentPlayer(message.playerColor);
				gui.showDiceValues(message.playerColor, null, null);
				gui.showSubmitButton("Roll");
				return true;
			} else {
				return false;
			}
		} else {
			gui.showPlayerMessage(message.playerColor, "Starting...", false);
			gui.showDiceValues(message.playerColor, message.diceValue, null);
			return true;
		}
	}
	
	function showTurnStart(StartTurnMessage message) {
		game.endTurn(message.playerColor.oppositeColor);
		if (game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo)) {
			gui.showDiceValues(message.playerColor.oppositeColor, null, null);
			gui.showDiceValues(message.playerColor, message.roll.firstValue, message.roll.secondValue);
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, "Timeout"), true);
			gui.showPlayerMessage(message.playerColor.oppositeColor, "Waiting...", false);
			gui.showCurrentPlayer(message.playerColor);
			if (message.playerId == playerId) {
				gui.showSubmitButton(null);
			} else {
				gui.hideSubmitButton();
			}
			return true;
		} else {
			return false;
		}
	}
	
	// TODO refactor this method
	void showGameState() {
		value currentTime = now();
		gui.showCurrentPlayer(game.currentColor);
		if (exists currentColor = game.currentColor, exists currentRoll = game.currentRoll) {
			gui.showDiceValues(currentColor, currentRoll.firstValue, currentRoll.secondValue);
			gui.showDiceValues(currentColor.oppositeColor, null, null);
		} else if (exists currentRoll = game.currentRoll) {
			if (exists currentColor = playerColor) {
				gui.showDiceValues(currentColor, null, null);
				gui.showDiceValues(currentColor.oppositeColor, currentRoll.getValue(currentColor.oppositeColor), null);
				gui.showCurrentPlayer(currentColor);
			} else {
				gui.showDiceValues(black, currentRoll.getValue(black), null);
				gui.showDiceValues(white, currentRoll.getValue(white), null);
			}
		} else {
			gui.showDiceValues(black, null, null);
			gui.showDiceValues(white, null, null);
		}
		gui.redrawCheckers(game.board);
		if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(currentTime)) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime, "Timeout"), true);
			gui.showPlayerMessage(currentColor.oppositeColor, "Waiting...", true);
			if (exists color = playerColor, currentColor == color) {
				gui.showSubmitButton(null);
			} else {
				gui.hideSubmitButton();
			}
		} else if (game.ended) {
			showWin(game.winner);
		} else { 
			
			gui.showPlayerMessage(black, "Starting...", false);
			gui.showPlayerMessage(white, "Starting...", false);
			
			if (exists color = playerColor, game.mustRollDice(color), exists remainingTime = game.remainingTime(currentTime)) {
				gui.showSubmitButton("Roll");
				gui.showPlayerMessage(color, gui.formatPeriod(remainingTime, "Timeout"), true);
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
	
	function showGameWon(GameWonMessage message) {
		if (game.end()) {
			showWin(message.playerColor);
			return true;
		} else {
			return false;
		}
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
			return false;
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
			return showGameWon(message);
		}
		case (is GameEndedMessage) {
			game.end();
			showWin(game.winner);
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
		case (is TurnTimedOutMessage) {
			// TODO force timeout in game
			if (exists currentColor = game.currentColor) {
				gui.showPlayerMessage(currentColor, "Timeout", false);
			} else {
				gui.showPlayerMessage(player1Color, "Timeout", true);
				gui.showPlayerMessage(player2Color, "Timeout", true);
			}
			return true;
		}
	}
	
	void handleDelayedActions(Instant time) {
		for (element in delayedMessage.select((DelayedGameMessage element) => element.mustSend(time))) {
			messageBroadcaster(element.message);
		}
		delayedMessage = delayedMessage.select((DelayedGameMessage element) => !element.mustSend(time));
	}
	
	shared Boolean handleTimerEvent(Instant time) {
		
		handleDelayedActions(time);
		
		if (game.timedOut(time)) {
			return true;
		} else if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(time)) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime, "Timeout"), true);
			return true;
		} else if (exists currentColor = playerColor, game.mustRollDice(currentColor), exists remainingTime = game.remainingTime(time)) {
			gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime, "Timeout"), true);
			return true;
		} else {
			return true;
		}
	}
	
	shared void showState() {
		showGameState();
	}
	
	shared Boolean handleSubmitEvent() {
		if (exists color = playerColor, game.mustRollDice(color), exists currentRoll = game.currentRoll) {
			if (game.begin(color)) { // TODO should not modify game state here
				gui.showDiceValues(color, currentRoll.getValue(color), null);
				gui.hideSubmitButton();
				gui.showPlayerMessage(color, "Ready", false);
				delayedMessage = delayedMessage.withTrailing(DelayedGameMessage(PlayerReadyMessage(matchId, playerId), initialRollDelay));
				return true;
			} else {
				return false;
			}
		} else if (exists color = playerColor, game.mustMakeMove(color)) {
			if (game.isCurrentColor(color)) {
				gui.hidePossibleMoves();
				gui.showSelectedChecker(null);
				gui.hideSubmitButton();
				messageBroadcaster(EndTurnMessage(matchId, playerId));
				return true;
			} else {
				return false;
			}
		} else {
			// TODO this error still occurs
			print("Strange state: ``game.state.toJson()``");
			return false;
		}
	}
	
	shared Boolean hasRunningGame {
		return game.ended;
	}
	
	shared Boolean handleStartDrag(HTMLElement source) {
		gui.showSelectedChecker(null);
		gui.hidePossibleMoves();
		if (exists color = playerColor, game.mustMakeMove(color), exists roll = game.currentRoll, exists position = gui.getPosition(source)) {
			value moves = game.computeAvailableMoves(color, roll, position);
			if (!moves.empty) {
				gui.showPossibleMoves(game.board, color, moves.map((GameMove element) => element.targetPosition));
				return true;
			} else {
				return false;
			}
			
		} else {
			return false;
		}
	}
	
	function makeMove(Integer sourcePosition, Integer targetPosition) {
		if (exists color = playerColor, game.isLegalMove(color, sourcePosition, targetPosition)) {
			gui.showSelectedChecker(null);
			gui.hidePossibleMoves();
			messageBroadcaster(MakeMoveMessage(matchId, playerId, sourcePosition, targetPosition));
			return false;
		} else {
			gui.redrawCheckers(game.board);
			return false;
		}
	}
	
	shared Boolean handleCheckerSelection(HTMLElement checker) {
		if (gui.isTempChecker(checker), exists sourcePosition = gui.getSelectedCheckerPosition(), exists targetPosition = gui.getPosition(checker)) {
			return makeMove(sourcePosition, targetPosition);
		} else if (handleStartDrag(checker)) {
			gui.showSelectedChecker(checker);
			return true;
		} else {
			return false;
		}
	}
	
	
	shared Boolean handleDrop(HTMLElement targetElement, HTMLElement sourceElement) {
		if (exists sourcePosition = gui.getPosition(sourceElement), exists targetPosition = gui.getPosition(targetElement)) {
			return makeMove(sourcePosition, targetPosition);
		} else {
			return false;
		}
		
	}
}