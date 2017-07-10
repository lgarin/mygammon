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
	
	shared String neo4jUrl = json?.getStringOrNull("neo4jUrl") else "bolt://localhost:7687";
	shared String neo4jUser = json?.getStringOrNull("neo4jUser") else "neo4j";
	shared String neo4jPass = json?.getStringOrNull("neo4jPass") else "neo4j";
	shared String brokerUrl = json?.getStringOrNull("brokerUrl") else  "tcp://127.0.0.1:5672"; 
	
	shared String hostname = json?.getStringOrNull("hostname") else "localhost";
	shared Integer port = json?.getIntegerOrNull("port") else 8080;
	shared String repositoryFile = json?.getStringOrNull("repositoryFile") else "resource/player-roster.json";
	shared String databaseFile = json?.getStringOrNull("databaseFile") else "resource/neo4j.db";
	shared Duration userSessionTimeout => Duration(playerInactiveTimeout.milliseconds + serverAdditionalTimeout.milliseconds);
}
