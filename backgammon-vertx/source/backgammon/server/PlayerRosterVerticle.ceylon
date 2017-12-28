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
	Verticle,
	Future
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
	
	shared actual void startAsync(Future<Anything> startFuture) {
		value serverConfig = ServerConfiguration(config);
		value roster = PlayerRoster(serverConfig);
		value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);
		
		log.info("Starting player roster");
		repoEventBus.replayAllEvents(roster.processInputMessage, (result) {
			if (is Exception result) {
				startFuture.fail(result);
			} else {
				repoEventBus.registerConsumer(roster.processInputMessage);
				
				vertx.setPeriodic(serverConfig.rosterStatisticInterval.milliseconds, void (Integer val) {
					handleStatistic(roster);
				});
				
				log.info("Replayed ``result`` events in player roster");
				startFuture.complete();
			}
		});
	}
	
	shared actual void stop() {
		log.info("Stopped player roster");
	}
}