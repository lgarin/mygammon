import backgammon.server.bus {
	PlayerRosterEventBus
}
import backgammon.server.roster {
	PlayerRoster
}

import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle
}


final class PlayerRosterVerticle() extends Verticle() {
	
	value log = logger(`package`);
	
	variable String lastStatistic = "";
	
	void handleStatistic(PlayerRoster playerRoster) {
		value statistic = playerRoster.statistic.string;
		if (statistic != lastStatistic) {
			lastStatistic = statistic;
			log.info(statistic);
		}
	}
	
	shared actual void start() {
		value serverConfig = ServerConfiguration(config);
		value roster = PlayerRoster(serverConfig);
		
		value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);
		
		log.info("Starting player roster");
		
		repoEventBus.replayAllEvents(roster.processInputMessage, (result) {
			if (is Exception result) {
				log.fatal("Cannot restore player roster state", result);
				// TODO how to handle this?
			} else {
				repoEventBus.registerConsumer(roster.processInputMessage);
				
				vertx.setPeriodic(1000, void (Integer val) {
					handleStatistic(roster);
				});
				
				log.info("Replayed ``result`` events in player roster");
			}
		});
	}
	
	shared actual void stop() {
		log.info("Stopped player roster");
	}
}