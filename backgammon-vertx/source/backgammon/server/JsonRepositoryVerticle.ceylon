import backgammon.server.roster {
	JsonPlayerRoster
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
		value serverConfig = ServerConfiguration(config);
		value repository = JsonPlayerRoster(serverConfig);
		repository.readData(serverConfig.repositoryFile);
		_playerRepository = repository;
		value repoEventBus = PlayerRosterEventBus(vertx);
		repoEventBus.registerConsumer(repository.processInputMessage);
		log.info("Started repository : ``serverConfig.repositoryFile``");
		log.info(repository.statistic.string);
	}
	
	shared actual void stop() {
		value serverConfig = ServerConfiguration(config);
		if (exists repository = _playerRepository) {
			repository.writeData(serverConfig.repositoryFile);
			log.info(repository.statistic.string);
		}
		log.info("Stopped repository : ``serverConfig.repositoryFile``");
	}
}