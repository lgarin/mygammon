import ceylon.time {

	Duration
}
import backgammon.game {

	GameConfiguration
}
shared final class RoomConfiguration(shared String roomName, shared Integer tableCount, Duration maxTurnDuration, shared Duration maxMatchJoinTime) extends GameConfiguration(maxTurnDuration) {
	shared Duration sessionTimeout = Duration(10 * 60 * 1000);
}