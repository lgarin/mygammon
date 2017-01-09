import backgammon.server.roster {
	JsonPlayerRoster
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
	
	variable JsonPlayerRoster? _playerRepository = null;
	value log = logger(`package`);
	
	shared actual void start() {
		value roomConfig = RoomConfiguration(config);
		value repository = JsonPlayerRoster(roomConfig);
		repository.readData(roomConfig.repositoryFile);
		_playerRepository = repository;
		value repoEventBus = PlayerRosterEventBus(vertx);
		repoEventBus.registerConsumer(repository.processInputMessage);
		log.info("Started repository : ``roomConfig.repositoryFile``");
		log.info(repository.statistic.string);
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		if (exists repository = _playerRepository) {
			repository.writeData(roomConfig.repositoryFile);
			log.info(repository.statistic.string);
		}
		log.info("Stopped repository : ``roomConfig.repositoryFile``");
	}
}