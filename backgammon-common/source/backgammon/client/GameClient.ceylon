import backgammon.game {
	Game,
	GameConfiguration,
	CheckerColor,
	black,
	white
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
	GameEndedMessage
}
import ceylon.interop.browser {

	window
}
import ceylon.time {

	Duration,
	Period
}
shared class GameClient(String playerId, Anything(InboundGameMessage) messageBroadcaster) {
	value game = Game();
	value gui = GameGui(window.document);
	
	variable Integer? initialDiceValue = null;
	variable CheckerColor? playerColor = null;
	
	
	
	function showInitialRoll(InitialRollMessage message) {
		if (message.playerId == playerId) {
				game.initialRoll(message.roll, message.maxDuration);
				initialDiceValue = message.diceValue;
				playerColor = message.playerColor;
				// TODO start timer
			} else {
				gui.showDiceValues(message.playerColor.oppositeColor, message.diceValue, null);
			}
		return true;
	}
	
	String formatSeconds(Integer seconds) => if (seconds < 10) then "0" + seconds.string else seconds.string;
	String formatPeriod(Period period) => "``period.minutes``:``formatSeconds(period.seconds)``";
	
	function showTurnStart(StartTurnMessage message) {
		game.beginTurn(message.playerColor, message.roll, message.maxDuration, message.maxUndo);
		gui.showDiceValues(message.playerColor.oppositeColor, null, null);
		gui.showDiceValues(message.playerColor, message.roll.firstValue, message.roll.secondValue);
		gui.showPlayerMessage(message.playerColor, formatPeriod(message.maxDuration.period), false);
		gui.showPlayerMessage(message.playerColor.oppositeColor, "Waiting", false); // TODO start timer		return true;
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
			game.moveChecker(message.playerColor, message.move.sourcePosition, message.move.targetPosition);
			gui.redrawCheckers(message.playerColor, game.checkerCounts(message.playerColor));
			return true;
		}
		case (is UndoneMovesMessage) {
			game.undoTurnMoves(message.playerColor);
			return true;
		}
		case (is InvalidMoveMessage) {
			// TODO restore state
		}
		case (is DesynchronizedMessage) {
			game.state = message.state;
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
			gui.redrawCheckers(black, message.state.blackCheckerCounts);
			gui.redrawCheckers(white, message.state.whiteCheckerCounts);
			gui.showCurrentPlayer(game.currentColor);
			if (!message.state.blackReady) {
				gui.showPlayerMessage(black, "Waiting", true);
			}
			if (!message.state.whiteReady) {
				gui.showPlayerMessage(white, "Waiting", true);
			}
			
			// TODO restore timer
			// TODO restore player info
		}
		case (is NotYourTurnMessage) {
			// TODO restore state
		}
		case (is GameWonMessage) {
			// TODO stop timer
			if (message.playerId == playerId) {
				// TODO show win
			} else {
				// TODO show lost
			}
			return true;
		}
		case (is GameEndedMessage) {
			return true;
		}
		
		return false;
	}
}