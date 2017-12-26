import backgammon.server.room {
	RoomConfiguration
}

import ceylon.json {
	Object
}
import ceylon.time {

	Duration
}
shared final class ServerConfiguration(Object? json) extends RoomConfiguration(json) {
	shared String keycloakRealm = json?.getStringOrNull("keycloakRealm") else "MyGammon";
	shared String keycloakUrl = json?.getStringOrNull("keycloakUrl") else "http://localhost:8080/auth";

	shared String hostname = json?.getStringOrNull("hostname") else "localhost";
	shared Integer port = json?.getIntegerOrNull("port") else 8081;
	shared String repositoryFile = json?.getStringOrNull("repositoryFile") else "resource/player-roster.json";
	shared Duration userSessionTimeout => Duration(playerInactiveTimeout.milliseconds + serverAdditionalTimeout.milliseconds);
}
