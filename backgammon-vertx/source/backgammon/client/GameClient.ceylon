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
	InboundGameMessage
}
import backgammon.shared.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color,
	DiceRoll,
	GameMoveInfo
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
	variable [GameMoveInfo*] nextMoves = [];
	
	void showInitialDices(DiceRoll roll) {
		if (exists currentColor = playerColor, game.mustRollDice(currentColor)) {
			gui.showDiceValues(currentColor, null, null);
			gui.showDiceValues(currentColor.oppositeColor, roll.getValue(currentColor.oppositeColor), null);
		} else {
			gui.showDiceValues(black, roll.getValue(black), null);
			gui.showDiceValues(white, roll.getValue(white), null);
		}
	}
	
	void showTurnDices(DiceRoll roll, CheckerColor color) {
		gui.showDiceValues(color.oppositeColor, null, null);
		gui.showDiceValues(color, roll.firstValue, roll.secondValue);
	}
	
	void hideDices() {
		gui.showDiceValues(black, null, null);
		gui.showDiceValues(white, null, null);
	}
	
	void showInitialRollMessages(Duration remainingTime) {
		if (game.mustRollDice(black)) {
			gui.showPlayerMessage(black, gui.formatPeriod(remainingTime, "Timeout"), true);
		} else {
			gui.showPlayerMessage(black, "Ready", false);
		}
		if (game.mustRollDice(white)) {
			gui.showPlayerMessage(white, gui.formatPeriod(remainingTime, "Timeout"), true);
		} else {
			gui.showPlayerMessage(white, "Ready", false);
		}
		
		if (exists color = playerColor, game.mustRollDice(color)) {
			gui.showCurrentPlayer(playerColor);
		} else {
			gui.showCurrentPlayer(null);
		}
	}
	
	void showCurrentTurnMessages(CheckerColor currentColor, Duration remainingTime) {
		gui.showPlayerMessage(currentColor, gui.formatPeriod(remainingTime, "Timeout"), true);
		gui.showPlayerMessage(currentColor.oppositeColor, "Waiting...", true);
		
		if (exists color = playerColor, game.mustMakeMove(color)) {
			gui.showCurrentPlayer(playerColor);
		} else {
			gui.showCurrentPlayer(null);
		}
	}
	
	void showLoadingMessages() {
		gui.showPlayerMessage(black, "Loading...", true);
		gui.showPlayerMessage(white, "Loading...", true);
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
			gui.showSubmitButton("Roll");
		} else if (exists color = playerColor, game.mustMakeMove(color)) {
			gui.showSubmitButton();
		} else {
			gui.hideSubmitButton();
		}
		
		if (exists color = playerColor, game.canUndoMoves(color)) {
			gui.showUndoButton();
		} else {
			gui.hideUndoButton();
		}
		
		gui.showLeaveButton();
	}
	
	function showInitialRoll(InitialRollMessage message) {
		gui.showCurrentPlayer(null);
		if (message.playerId == playerId) {
			if (game.initialRoll(message.roll, message.maxDuration)) {
				gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, "Timeout"), true);
				showInitialDices(message.roll);
				gui.showSubmitButton("Roll");
				return true;
			} else {
				return false;
			}
		} else {
			gui.showPlayerMessage(message.playerColor, gui.formatPeriod(message.maxDuration, "Timeout"), true);
			showInitialDices(message.roll);
			return true;
		}
	}
	
	function showPlayerReady(PlayerReadyMessage message) {
		if (game.begin(message.playerColor)) {
			gui.showPlayerMessage(message.playerColor, "Ready", false);
			return true;
		} else {
			return false;
		}
	}
	
	function showTurnStart(StartTurnMessage message) {
		game.endTurn(message.playerColor.oppositeColor);
		if (game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo)) {
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
			return true;
		} else {
			return false;
		}
	}
	
	function showPlayedMove(PlayedMoveMessage message) {
		if (game.moveChecker(message.playerColor, message.sourcePosition, message.targetPosition)) {
			gui.redrawCheckers(game.board);
			if (exists color = playerColor, game.canUndoMoves(color)) {
				gui.showUndoButton();
			}
			if (exists color = playerColor, exists nextMove = nextMoves.first, game.isLegalMove(color, nextMove.sourcePosition, nextMove.targetPosition)) {
				nextMoves = nextMoves.rest;
				messageBroadcaster(MakeMoveMessage(matchId, playerId, nextMove.sourcePosition, nextMove.targetPosition));
			} else {
				nextMoves = [];
			}
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
				return false;
			} else {
				return true;
			}
		}
		case (is DesynchronizedMessage) {
			if (message.playerId == playerId) {
				game.state = message.state;
				showState();
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
			game.state = message.state;
			showState();
			return true;
		}
		case (is GameActionResponseMessage) {
			return message.success;
		}
		case (is TurnTimedOutMessage) {
			game.forceTimeout();
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
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
			showCurrentTurnMessages(currentColor, remainingTime);
			return true;
		} else if (game.currentRoll exists, exists remainingTime = game.remainingTime(time)) {
			showInitialRollMessages(remainingTime);
			return true;
		} else {
			return true;
		}
	}
	
	shared Boolean handleSubmitEvent() {
		if (exists color = playerColor, game.mustRollDice(color)) {
			gui.showDiceValues(color, game.currentRoll?.getValue(color), null);
			gui.hideSubmitButton();
			delayedMessage = delayedMessage.withTrailing(DelayedGameMessage(PlayerBeginMessage(matchId, playerId), initialRollDelay));
			return true;
		} else if (exists color = playerColor, game.mustMakeMove(color)) {
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideSubmitButton();
			gui.hideUndoButton();
			messageBroadcaster(EndTurnMessage(matchId, playerId));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleUndoEvent() {
		if (exists color = playerColor, game.canUndoMoves(color)) {
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
			gui.hideUndoButton();
			messageBroadcaster(UndoMovesMessage(matchId, playerId));
			return true;
		} else {
			return false;
		}
	}

	shared Boolean handleStartDrag(HTMLElement source) {
		gui.showSelectedChecker(null);
		gui.hidePossibleMoves();
		if (exists color = playerColor, game.mustMakeMove(color), exists roll = game.currentRoll, exists position = gui.getPosition(source)) {
			value moves = game.computeNextMoves(color, roll, position);
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
			gui.hideChecker(checker);
			messageBroadcaster(MakeMoveMessage(matchId, playerId, moves.first.sourcePosition, moves.first.targetPosition));
			nextMoves = moves.rest;
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean handleCheckerSelection(HTMLElement checker) {
		if (gui.isTempChecker(checker), exists sourcePosition = gui.getSelectedCheckerPosition(), exists targetPosition = gui.getPosition(checker)) {
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