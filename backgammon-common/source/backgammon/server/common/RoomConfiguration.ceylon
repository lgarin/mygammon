import ceylon.time {

	Duration
}
import backgammon.game {

	GameConfiguration
}
shared final class RoomConfiguration(shared String roomName, shared Integer tableCount, Duration maxTurnDuration, shared Boolean useCaching = false) extends GameConfiguration(maxTurnDuration) {
	shared Duration sessionTimeout = Duration(10 * 60 * 1000);
	shared Integer roomThreadCount = 2;
	shared Integer gameThreadCount = 10;
}