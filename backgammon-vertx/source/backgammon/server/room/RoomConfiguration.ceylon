import backgammon.shared.game {
	GameConfiguration
}
import ceylon.json {
	Object
}
import ceylon.time {

	Duration
}

shared final class RoomConfiguration(Object? json) extends GameConfiguration(json) {
	shared String homeUrl = json?.getStringOrNull("homeUrl") else "http://mygammon.com";
	shared String roomId = json?.getStringOrNull("roomId") else "test";
	shared Integer initialPlayerBalance = json?.getIntegerOrNull("initialPlayerBalance") else 1000;
	shared Integer playerBet = json?.getIntegerOrNull("playerBet") else 110;
	shared Integer matchPot = json?.getIntegerOrNull("matchPot") else 200;
	shared Integer maxTableCount = json?.getIntegerOrNull("maxTableCount") else 10;
	shared Integer maxPlayerCount = json?.getIntegerOrNull("maxPlayerCount") else 100;
	shared Integer roomThreadCount = json?.getIntegerOrNull("roomThreadCount") else 2;
	shared Integer gameThreadCount = json?.getIntegerOrNull("gameThreadCount") else 4;
	shared Integer maxPlayerMessageRate = json?.getIntegerOrNull("maxPlayerMessageRate") else 10;
	shared String hostname = json?.getStringOrNull("hostname") else "localhost";
	shared Integer port = json?.getIntegerOrNull("port") else 8080;
	shared Duration userSessionTimeout => Duration(playerInactiveTimeout.milliseconds + serverAdditionalTimeout.milliseconds);
	shared RoomSize roomSize => RoomSize(maxTableCount, maxPlayerCount);
	shared MatchBet matchBet => MatchBet(playerBet, matchPot);
}
