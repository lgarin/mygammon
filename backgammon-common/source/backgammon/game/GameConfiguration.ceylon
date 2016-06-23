import ceylon.time {

	Duration
}
shared class GameConfiguration(shared Duration maxTurnDuration) {
	
	shared Duration maxRollDuration = Duration(maxTurnDuration.milliseconds / 2);
	shared Duration maxEmptyTurnDuration = Duration(maxTurnDuration.milliseconds / 4);
	shared Duration serverAdditionalTimeout = Duration(1000);
	
	shared Integer maxWarningCount = 3;
	shared Integer invalidMoveWarningCount = 2;
	shared Integer timeoutActionWarningCount = 1;
	shared Integer maxUndoPerTurn = 1;
}