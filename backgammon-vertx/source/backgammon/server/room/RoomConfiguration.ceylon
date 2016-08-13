import backgammon.shared.game {
	GameConfiguration
}
import ceylon.json {
	Object
}

shared final class RoomConfiguration(Object? json) extends GameConfiguration(json) {
	shared String roomId = json?.getStringOrNull("roomId") else "test";
	shared Integer tableCount = json?.getIntegerOrNull("tableCount") else 1;
	shared Integer roomThreadCount = json?.getIntegerOrNull("roomThreadCount") else 2;
	shared Integer gameThreadCount = json?.getIntegerOrNull("gameThreadCount") else 10;
	shared String hostname = json?.getStringOrNull("hostname") else "localhost";
	shared Integer port = json?.getIntegerOrNull("port") else 8080;
}
