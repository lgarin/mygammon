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
	PlayerBeginMessage,
	EndTurnMessage,
	MakeMoveMessage,
	TurnTimedOutMessage,
	PlayerReadyMessage,
	UndoMovesMessage
}
import backgammon.game {
	Game,
	CheckerColor,
	black,
	white,
	player2Color,
	player1Color,
	GameMove,
	DiceRoll
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
	
	void showWinMessages(CheckerColor? color) {
		if (exists currentColor = color) {
			gui.showPlayerMessage(currentColor, "Winner", false);
			gui.showPlayerMessage(currentColor.oppositeColor, "", false);
		} else {
			gui.showPlayerMessage(player1Color, "Tie", false);
			gui.showPlayerMessage(player2Color, "Tie", false);
		}
		gui.showCurrentPlayer(color);
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
		} else if (game.ended) {
			showWinMessages(game.winner);
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
		gui.hidePossibleMoves();
		gui.showSelectedChecker(null);
		showWinMessages(color);
		gui.hideSubmitButton();
		gui.hideUndoButton();
		gui.showLeaveButton();
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
			return false;
		}
		case (is DesynchronizedMessage) {
			game.state = message.state;
			showState();
			return true;
		}
		case (is NotYourTurnMessage) {
			return false;
		}
		case (is GameWonMessage) {
			// TODO force win in game
			return showGameWon(message);
		}
		case (is GameEndedMessage) {
			game.end();
			showWin(game.winner);
			return true;
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
			gui.hidePossibleMoves();
			gui.showSelectedChecker(null);
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
			// TODO this error still occurs
			print("Strange state: ``game.state.toJson()``");
			gui.hideSubmitButton();
			messageBroadcaster(PlayerBeginMessage(matchId, playerId));
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
	
	function makeMove(Integer sourcePosition, Integer targetPosition, HTMLElement checker) {
		if (exists color = playerColor, game.isLegalMove(color, sourcePosition, targetPosition)) {
			gui.showSelectedChecker(null);
			gui.hidePossibleMoves();
			gui.hideChecker(checker);
			messageBroadcaster(MakeMoveMessage(matchId, playerId, sourcePosition, targetPosition));
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