import ceylon.time {

	Duration
}
import backgammon.game {

	GameConfiguration
}
shared final class RoomConfiguration(shared String roomName, shared Integer tableCount, Duration maxTurnDuration) extends GameConfiguration(maxTurnDuration) {
	shared Integer roomThreadCount = 2;
	shared Integer gameThreadCount = 10;
}