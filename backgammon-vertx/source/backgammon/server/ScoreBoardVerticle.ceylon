import backgammon.server.bus {
	PlayerRosterEventBus,
	ScoreBoardEventBus
}
import backgammon.server.score {
	ScoreBoard
}
import backgammon.shared {
	InboundScoreBoardMessage,
	OutboundScoreBoardMessage,
	GameStatisticMessage,
	PlayerStatisticRequestMessage,
	PlayerStatisticOutputMessage
}

import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle,
	Future
}
final class ScoreBoardVerticle() extends Verticle() {
	
	value log = logger(`package`);
	
	shared actual void startAsync(Future<Anything> startFuture) {
		value serverConfig = ServerConfiguration(config);
		value scoreEventBus = ScoreBoardEventBus(vertx, serverConfig);
		value rosterEventBus = PlayerRosterEventBus(vertx, serverConfig);
		value scoreBoard = ScoreBoard(serverConfig);

		void processInputMessage(InboundScoreBoardMessage message, Anything(OutboundScoreBoardMessage|Throwable) callback) {
			
			void processMessage(PlayerStatisticOutputMessage playerStatistic)({GameStatisticMessage*}|Throwable result) {
				if (is Throwable result) {
					callback(result);
				} else {
					callback(scoreBoard.processInputMessage(message, playerStatistic, result));
				}
			}
			
			void queryGameHistory(Throwable|PlayerStatisticOutputMessage response) {
				if (is Throwable response) {
					callback(response);
				} else {
					scoreEventBus.queryGameStatisticMessages(message.playerId, processMessage(response));
				}
			}
			
			if (message.mutation) {
				callback(scoreBoard.processInputMessage(message));
			} else {
				rosterEventBus.sendInboundMessage(PlayerStatisticRequestMessage(message.playerId, message.timestamp), queryGameHistory);
			}
		}
		
		scoreEventBus.disableOutput = true;
		log.info("Starting score board...");
		scoreEventBus.replayAllEvents(scoreBoard.processInputMessage, (result) {
			if (is Throwable result) {
				startFuture.fail(result);
			} else {
				scoreEventBus.registerAsyncConsumer(processInputMessage);
				
				scoreEventBus.disableOutput = false;
				log.info("Score board events : ``result``");
				startFuture.complete();
			}
		});
	}
	
	shared actual void stop() {
		log.info("Stopped score board");
	}
}