import backgammon.server.repository {
	JsonPlayerRepository
}
import backgammon.server.room {
	RoomConfiguration
}

import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle
}
final class JsonRepositoryVerticle() extends Verticle() {
	
	variable JsonPlayerRepository? _playerRepository = null;
	value log = logger(`package`);
	
	shared actual void start() {
		value roomConfig = RoomConfiguration(config);
		value repository = JsonPlayerRepository();
		repository.readData(roomConfig.repositoryFile);
		_playerRepository = repository;
		value repoEventBus = PlayerRepositoryEventBus(vertx);
		repoEventBus.registerConsumer(repository.processInputMessage);
		log.info("Started repository : ``roomConfig.repositoryFile``");
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		_playerRepository?.writeData(roomConfig.repositoryFile);
		log.info("Stopped repository : ``roomConfig.repositoryFile``");
	}
}