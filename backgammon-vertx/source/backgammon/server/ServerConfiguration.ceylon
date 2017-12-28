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
	shared String keycloakLoginUrl = json?.getStringOrNull("keycloakLoginUrl") else "http://localhost:8080/auth/realms/MyGammon/protocol/openid-connect";
	shared String elasticIndexUrl =  json?.getStringOrNull("elasticIndexUrl") else "http://localhost:9200";

	shared Integer replayPageSize = json?.getIntegerOrNull("replayPageSize") else 1000;
	
	shared String hostname = json?.getStringOrNull("hostname") else "localhost";
	shared Integer port = json?.getIntegerOrNull("port") else 8081;
	
	shared Duration rosterStatisticInterval = Duration(json?.getIntegerOrNull("rosterStatisticInterval") else 1000);
	shared Duration userSessionTimeout => Duration(playerInactiveTimeout.milliseconds + serverAdditionalTimeout.milliseconds);
}
