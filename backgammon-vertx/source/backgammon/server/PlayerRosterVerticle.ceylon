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
import backgammon.shared {

	InboundPlayerRosterMessage,
	OutboundPlayerRosterMessage
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
		value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);
		value roster = PlayerRoster(serverConfig, repoEventBus.queueInboundMessage);

		void processInputMessage(InboundPlayerRosterMessage message, Anything(OutboundPlayerRosterMessage|Throwable) callback) {
			void processPlayerHistory({InboundPlayerRosterMessage*}|Throwable result) {
				if (is Throwable result) {
					callback(result);
				} else {
					callback(roster.processInputMessage(message, result));
				}
			}
			
			if (message.mutation) {
				callback(roster.processInputMessage(message));
			} else {
				repoEventBus.queryInboundPlayerMessages(message.playerId, processPlayerHistory);
			}
		}
		
		repoEventBus.disableOutput = true;
		log.info("Starting player roster...");
		repoEventBus.replayAllEvents(roster.processInputMessage, (result) {
			if (is Throwable result) {
				startFuture.fail(result);
			} else {
				repoEventBus.registerAsyncConsumer(processInputMessage);
				
				vertx.setPeriodic(serverConfig.rosterStatisticInterval.milliseconds, void (Integer val) {
					handleStatistic(roster);
				});
				
				repoEventBus.disableOutput = false;
				log.info("Replayed ``result`` events in player roster");
				startFuture.complete();
			}
		});
	}
	
	shared actual void stop() {
		log.info("Stopped player roster");
	}
}