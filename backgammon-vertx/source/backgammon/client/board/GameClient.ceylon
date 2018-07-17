import backgammon.client.browser {
	HTMLElement
}
import backgammon.shared {
	PlayerId,
	MatchId,
	UndoneMovesMessage,
	UndoMovesMessage,
	StartTurnMessage,
	GameActionResponseMessage,
	PlayerReadyMessage,
	InitialRollMessage,
	TurnTimedOutMessage,
	MakeMoveMessage,
	EndTurnMessage,
	InvalidMoveMessage,
	GameStateResponseMessage,
	OutboundGameMessage,
	DesynchronizedMessage,
	PlayedMoveMessage,
	NotYourTurnMessage,
	PlayerBeginMessage,
	InboundGameMessage,
	TakeTurnMessage,
	InvalidRollMessage,
	ControlRollMessage,
	takeTurnJoker,
	controlRollJoker
}
import backgammon.shared.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color,
	DiceRoll,
	GameState
}

import ceylon.time {
	Instant,
	now,
	Duration
}
import backgammon.client {

	TableGui
}
shared final class GameClient(PlayerId playerId, MatchId matchId, CheckerColor? playerColor, TableGui gui, Anything(InboundGameMessage) messageBroadcaster) {
	
	// TODO should be part of configuration
	value initialRollDelay = Duration(2000);
	value moveSequenceDelay = Duration(300);
			
	value game = Game(Instant(1000 * 60 * 60 * 24 * 365 * 1000));
	
	final class DelayedGameMessage(shared InboundGameMessage message, Duration delay) {
		value sendTime = now().plus(delay);
		
		shared Boolean mustSend(Instant time) {
			return sendTime <= time || game.timedOut(time);
		}
	}
	
	variable [DelayedGameMessage*] delayedMessage = [];
	variable [PlayerBeginMessage|MakeMoveMessage|EndTurnMessage|TakeTurnMessage|ControlRollMessage*] nextActions = [];
	
	void addDelayedGameMessage(InboundGameMessage message, Duration delay) {
		delayedMessage = delayedMessage.withTrailing(DelayedGameMessage(message, delay));
	}
	
	void showInitialDices(DiceRoll roll) {
		gui.hideAllDices(black);
		gui.hideAllDices(white);
		
		if (exists currentColor = playerColor, game.mustRollDice(currentColor)) {
			gui.showActiveDice(currentColor.oppositeColor, 0, roll.getValue(currentColor.oppositeColor));
		} else {
			gui.showActiveDice(black, 0, roll.getValue(black));
			gui.showActiveDice(white, 0, roll.getValue(white));
		}
	}
	
	void showTurnDices(DiceRoll roll, CheckerColor color) {
		gui.hideAllDices(color.oppositeColor);

		value hasMove = game.hasAvailableMove(color, roll);
		value state = roll.state;
		for (index in 0..3) {
			if (exists diceState = state[index]) {
				if (!diceState.item) {
					gui.showFadedDice(color, index, diceState.key);
				} else if (!hasMove) {
					gui.showCrossedDice(color, index, diceState.key);
				} else {
					gui.showActiveDice(color, index, diceState.key);
				}
			} else {
				gui.showActiveDice(color, index, null);
			}
		}
	}
	
	void hideDices() {
		gui.hideAllDices(black);
		gui.hideAllDices(white);
	}
	
	void showInitialRollMessages(Duration remainingTime) {
		if (game.mustRollDice(black)) {
			gui.showPlayerMessage(black, gui.formatPeriod(remainingTime, gui.timeoutTextKey), true);
		} else {
			gui.showPlayerMessage(black, gui.readyTextKey, false);
		}
		if (game.mustRollDice(white)) {
			gui.showPlayerMessage(white, gui.formatPeriod(remainingTime, gui.timeoutTextKey), true);
		} else {
			gui.showPlayerMessage(white, gui.readyTextKey, false);
		}
		
		if (exists color = playerColor, game.mustRollDice(color)) {
			gui.showCurrentPlayer(playerColor);
		} else {
			gui.showCurrentPlayer(null);
		}
	}
	
	void showCurrentTurnMessages(CheckerColor currentColor, Duration remainingTime) {
		gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime, gui.timeoutTextKey), true);
		gui.showPlayerMessage(currentColor.oppositeColor, gui.waitingTextKey, true);
		
		if (!exists playerColor) {
			gui.showCurrentPlayer(currentColor);
		} else if (game.isCurrentColor(playerColor)) {
			gui.showCurrentPlayer(playerColor);
		} else {
			gui.showCurrentPlayer(null);
		}
	}
	
	void showLoadingMessages() {
		gui.showPlayerMessage(black, gui.loadingTextKey, true);
		gui.showPlayerMessage(white, gui.loadingTextKey, true);
		gui.showCurrentPlayer(null);
	}
	
	shared void showState() {
		value currentTime = now();
		
		if (exists currentColor = game.currentColor, exists currentRoll = game.currentRoll) {
			showTurnDices(currentRoll, currentColor);
		} else if (exists currentRoll = game.currentRoll) {
			showInitialDices(currentRoll);
		} else {
			hideDices();
		}
		
		gui.redrawCheckers(game.board);
		
		if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(currentTime)) {
			showCurrentTurnMessages(currentColor, remainingTime);
		} else if (exists remainingTime = game.remainingTime(currentTime)) {
			showInitialRollMessages(remainingTime);
		} else {
			showLoadingMessages();
		}
		
		if (exists color = playerColor, game.mustRollDice(color)) {
			gui.showSubmitButton(gui.rollTextKey);
		} else if (exists color = playerColor, game.isCurrentColor(color)) {
			gui.showSubmitButton();
		} else {
			gui.hideSubmitButton();
		}
		
		if (exists color = playerColor, game.canUndoMoves(color)) {
			gui.showUndoButton();
		} else {
			gui.hideUndoButton();
		}
		
		if (exists color = playerColor, game.canPlayJoker(color)) {
			gui.showJokerButton();
		} else {
			gui.hideJokerButton();
		}
	}
	
	function showInitialRoll(InitialRollMessage message) {
		gui.showCurrentPlayer(null);
		if (message.playerId == playerId) {
			if (game.initialRoll(message.roll, now(), message.maxDuration)) {
				gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, gui.timeoutTextKey), true);
				showInitialDices(message.roll);
				gui.showSubmitButton(gui.rollTextKey);
				return true;
			} else {
				return false;
			}
		} else {
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, gui.timeoutTextKey), true);
			showInitialDices(message.roll);
			return true;
		}
	}
	
	function showPlayerReady(PlayerReadyMessage message) {
		if (game.begin(message.playerColor, now(), message.jokerCount)) {
			gui.showPlayerMessage(message.playerColor, gui.readyTextKey, false);
			nextActions = [PlayerBeginMessage(message.matchId, message.playerId, Instant(0))];
			return true;
		} else {
			return false;
		}
	}
	
	function showTurnStart(StartTurnMessage message) {
		
		if (nextActions.narrow<PlayerBeginMessage>().empty) {
			switch (message.joker)
			case (takeTurnJoker) {
				game.takeTurn(message.playerColor, now());
			}
			case (controlRollJoker) {
				game.controlRoll(message.playerColor.oppositeColor, now());
			}
			case (null) {
				game.endTurn(message.playerColor.oppositeColor, now());
			}
		}
		
		delayedMessage = [];
		nextActions = [];
		
		if (game.beginTurn(message.playerColor, message.roll, now(), message.maxDuration, message.maxUndo)) {
			showTurnDices(message.roll, message.playerColor);
			showCurrentTurnMessages(message.playerColor, message.maxDuration);
			if (message.playerId == playerId, nonempty forcedMoves = game.computeForcedMoves(message.playerColor, message.roll)) {
				gui.showPossibleMoves(game.board, message.playerColor, forcedMoves.map((element) => element.targetPosition));
				gui.showSelectedPosition(game.board, message.playerColor, forcedMoves.first.sourcePosition);
			}
			if (message.playerId == playerId) {
				gui.showSubmitButton();
			} else {
				gui.hideSubmitButton();
			}
			
			if (message.playerId == playerId && game.canPlayJoker(message.playerColor)) {
				gui.showJokerButton();
			} else {
				gui.hideJokerButton();
			}
			return true;
		} else {
			return false;
		}
	}
	
	function showPlayedMove(PlayedMoveMessage message) {
		if (game.moveChecker(message.playerColor, message.sourcePosition, message.targetPosition)) {
			gui.redrawCheckers(game.board);
			if (exists color = playerColor, game.canUndoMoves(color), nextActions.narrow<EndTurnMessage>().empty, nextActions.narrow<TakeTurnMessage>().empty) {
				gui.showUndoButton();
			}
			if (exists roll = game.currentRoll) {
				showTurnDices(roll, message.playerColor);
			}
			if (message.playerId == playerId, exists roll = game.currentRoll, nonempty forcedMoves = game.computeForcedMoves(message.playerColor, roll)) {
				gui.showPossibleMoves(game.board, message.playerColor, forcedMoves.map((element) => element.targetPosition));
				gui.showSelectedPosition(game.board, message.playerColor, forcedMoves.first.sourcePosition);
			}
			if (exists color = playerColor, exists nextAction = nextActions.first) {
				nextActions = nextActions.rest;
				addDelayedGameMessage(nextAction, moveSequenceDelay);
			}
			return true;
		} else {
			return false;
		}
	}
	
	function showUndoneMoves(UndoneMovesMessage message) {
		if (game.undoTurnMoves(message.playerColor)) {
			gui.redrawCheckers(game.board);
			if (exists color = playerColor, game.canUndoMoves(color)) {
				gui.showUndoButton();
			}
			if (exists roll = game.currentRoll) {
				showTurnDices(roll, message.playerColor);
			}
			return true;
		} else {
			return false;
		}
	}

	void resetState(GameState state) {
		delayedMessage = [];
		nextActions = [];
		game.resetState(state, now());
		showState();
	}
	
	void showTimeout() {
		gui.hideUndoButton();
		gui.hidePossibleMoves();
		gui.showSelectedChecker(null);
		if (exists currentColor = game.currentColor) {
			gui.showPlayerMessage(currentColor, gui.timeoutTextKey, false);
		} else {
			gui.showPlayerMessage(player1Color, gui.timeoutTextKey, true);
			gui.showPlayerMessage(player2Color, gui.timeoutTextKey, true);
		}
	}
	
	shared Boolean handleGameMessage(OutboundGameMessage message) {
		if (message.matchId != matchId) {
			return false;
		}
		
		switch (message) 
		case (is InitialRollMessage) {
			return showInitialRoll(message);
		}
		case (is PlayerReadyMessage) {
			return showPlayerReady(message);
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
			if (message.playerId == playerId) {
				delayedMessage = [];
				nextActions = [];
				return false;
			} else {
				return true;
			}
		}
		case (is InvalidRollMessage) {
			if (message.playerId == playerId) {
				return false;
			} else {
				return true;
			}
		}
		case (is DesynchronizedMessage) {
			if (message.playerId == playerId) {
				resetState(message.state);
			}
			return true;
		}
		case (is NotYourTurnMessage) {
			if (message.playerId == playerId) { 
				return false;
			} else {
				return true;
			}
		}
		case (is GameStateResponseMessage) {
			resetState(message.state);
			return true;
		}
		case (is GameActionResponseMessage) {
			return message.success;
		}
		case (is TurnTimedOutMessage) {
			delayedMessage = [];
			nextActions = [];
			game.forceTimeout(now());
			showTimeout();
			return true;
		}
	}
	
	void handleDelayedActions(Instant time) {
		for (element in delayedMessage.select((element) => element.mustSend(time))) {
			messageBroadcaster(element.message);
		}
		delayedMessage = delayedMessage.select((element) => !element.mustSend(time));
	}
	
	shared Boolean handleTimerEvent(Instant time) {
		
		handleDelayedActions(time);
		
		if (game.timedOut(time)) {
			return true;
		} else if (exists currentColor = game.currentColor, exists remainingTime = game.remainingTime(time)) {
			showCurrentTurnMessages(currentColor, remainingTime);
			return true;
		} else if (game.currentRoll exists, exists remainingTime = game.remainingTime(time)) {
			showInitialRollMessages(remainingTime);
			return true;
		} else {
			return true;
		}
	}
	
	value hasQueuedActions => !nextActions.empty || !delayedMessage.empty;
	
	shared Boolean handleSubmitEvent() {
		if (exists color = playerColor, game.mustRollDice(color)) {
			gui.showActiveDice(color, 0, game.currentRoll?.getValue(color));
			gui.hideSubmitButton();
			gui.hideJokerButton();
			addDelayedGameMessage(PlayerBeginMessage(matchId, playerId), initialRollDelay);
			return true;
		} else if (exists color = playerColor, game.isCurrentColor(color)) {
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideSubmitButton();
			gui.hideJokerButton();
			gui.hideUndoButton();
			
			if (hasQueuedActions) {
				nextActions = nextActions.withTrailing(EndTurnMessage(matchId, playerId));
			} else {
				messageBroadcaster(EndTurnMessage(matchId, playerId));
			}
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleUndoEvent() {
		if (exists color = playerColor, game.canUndoMoves(color)) {
			delayedMessage = [];
			nextActions = [];
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideUndoButton();
			messageBroadcaster(UndoMovesMessage(matchId, playerId));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleJokerEvent() {
		if (exists color = playerColor, game.canPlayJoker(color)) {
			gui.showJokerDialog(color);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleJokerDiceEvent(HTMLElement target) {
		if (exists color = playerColor) {
			gui.switchJokerDice(target, color);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleTakeTurnEvent() {
		if (exists color = playerColor, game.canTakeTurn(color)) {
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideJokerButton();
			gui.hideSubmitButton();
			gui.hideUndoButton();
			
			if (hasQueuedActions) {
				nextActions = nextActions.withTrailing(TakeTurnMessage(matchId, playerId));
			} else {
				messageBroadcaster(TakeTurnMessage(matchId, playerId));
			}
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleControlRollEvent() {
		if (exists color = playerColor, game.canControlRoll(color), exists roll = gui.readJokerRoll(color)) {
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideJokerButton();
			gui.hideSubmitButton();
			gui.hideUndoButton();
			
			if (hasQueuedActions) {
				nextActions = nextActions.withTrailing(ControlRollMessage(matchId, playerId, roll));
			} else {
				messageBroadcaster(ControlRollMessage(matchId, playerId, roll));
			}
			return true;
		} else {
			return false;
		}
	}

	shared Boolean handleStartDrag(HTMLElement source) {
		gui.showSelectedChecker(null);
		gui.hidePossibleMoves();
		if (hasQueuedActions) {
			return false;
		} else if (exists color = playerColor, game.isCurrentColor(color), exists roll = game.currentRoll, exists position = gui.getPosition(source)) {
			value moves = game.computeAllMoves(color, roll, position).keys;
			if (!moves.empty) {
				gui.showPossibleMoves(game.board, color, moves.map((element) => element.targetPosition));
				return true;
			} else {
				return false;
			}
			
		} else {
			return false;
		}
	}
	
	function makeMove(Integer sourcePosition, Integer targetPosition, HTMLElement checker) {
		if (exists color = playerColor, exists roll = game.currentRoll, nonempty moves = game.computeBestMoveSequence(color, roll, sourcePosition, targetPosition)) {
			gui.showSelectedChecker(null);
			gui.hidePossibleMoves();
			if (game.board.startPosition(color) == sourcePosition) {
				gui.resetCheckerCount(color, game.board.countCheckers(sourcePosition, color) - 1);
			} else {
				gui.hideChecker(checker);
			}
			value actions = moves.collect((element) => MakeMoveMessage(matchId, playerId, element.sourcePosition, element.targetPosition));
			nextActions = actions.rest;
			messageBroadcaster(actions.first);
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleCheckerSelection(HTMLElement checker) {
		if (hasQueuedActions) {
			return false;
		} else if (gui.isTempChecker(checker), exists sourcePosition = gui.getSelectedCheckerPosition(), exists targetPosition = gui.getPosition(checker)) {
			return makeMove(sourcePosition, targetPosition, checker);
		} else if (exists sourcePosition = gui.getSelectedCheckerPosition(), exists targetPosition = gui.getPosition(checker), sourcePosition == targetPosition, exists color = playerColor) {
			return makeMove(sourcePosition, game.board.homePosition(color), checker);
		} else if (handleStartDrag(checker)) {
			gui.showSelectedChecker(checker);
			return true;
		} else {
			return false;
		}
	}
	
	
	shared Boolean handleDrop(HTMLElement targetElement, HTMLElement sourceElement) {
		if (exists sourcePosition = gui.getPosition(sourceElement), exists targetPosition = gui.getPosition(targetElement)) {
			return makeMove(sourcePosition, targetPosition, sourceElement);
		} else {
			return false;
		}
		
	}
	
}