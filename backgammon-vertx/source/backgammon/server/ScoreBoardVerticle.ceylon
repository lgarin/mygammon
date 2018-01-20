import io.vertx.ceylon.core {

	Verticle
}
import ceylon.logging {

	logger
}
import backgammon.shared {

	InboundScoreBoardMessage,
	OutboundScoreBoardMessage,
	GameStatisticMessage,
	PlayerStatisticRequestMessage,
	PlayerStatisticOutputMessage
}
import backgammon.server.bus {

	PlayerRosterEventBus,
	ScoreBoardEventBus
}
import backgammon.server.score {

	ScoreBoard
}
final class ScoreBoardVerticle() extends Verticle() {
	
	value log = logger(`package`);
	
	shared actual void start() {
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
		
		log.info("Starting score board...");
		scoreEventBus.registerAsyncConsumer(processInputMessage);
	}
	
	shared actual void stop() {
		log.info("Stopped score board");
	}
}