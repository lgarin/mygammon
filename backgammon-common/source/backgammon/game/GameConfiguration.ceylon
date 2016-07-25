import ceylon.time {

	Duration
}
import ceylon.json {

	Object
}
shared class GameConfiguration(Object? json) {
	
	shared Duration maxTurnDuration = Duration(json?.getIntegerOrNull("maxTurnDuration") else 60000);
	shared Duration maxRollDuration = Duration(maxTurnDuration.milliseconds / 2);
	shared Duration maxEmptyTurnDuration = Duration(maxTurnDuration.milliseconds / 4);
	shared Duration serverAdditionalTimeout = Duration(json?.getIntegerOrNull("serverAdditionalTimeout") else 1000);
	shared Duration playerInactiveTimeout = Duration(json?.getIntegerOrNull("playerInactiveTimeout") else 1200000);
	shared Integer maxWarningCount = json?.getIntegerOrNull("maxWarningCount") else 3;
	shared Integer invalidMoveWarningCount = 2;
	shared Integer timeoutActionWarningCount = 1;
	shared Integer maxUndoPerTurn = json?.getIntegerOrNull("maxUndoPerTurn") else 1;
}