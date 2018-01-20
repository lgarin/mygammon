import backgammon.server {

	ServerConfiguration
}
import backgammon.shared {

	InboundScoreBoardMessage,
	PlayerStatisticOutputMessage,
	GameStatisticMessage,
	OutboundScoreBoardMessage,
	QueryGameStatisticMessage,
	ScoreBoardResponseMessage,
	GameStatisticResponseMessage,
	PlayerStatistic
}
import backgammon.server.util {

	ObtainableLock
}
shared final class ScoreBoard(ServerConfiguration config) {
	value lock = ObtainableLock("ScoreBoard");
	
	shared OutboundScoreBoardMessage processInputMessage(InboundScoreBoardMessage message, PlayerStatisticOutputMessage? playerStatistic = null, {GameStatisticMessage*}? gameHistory = null) {
		try (lock) {
			switch (message)
			case (is GameStatisticMessage) {
				// TODO compute average game time and score
				return ScoreBoardResponseMessage(message.matchId, true);
			}
			case (is QueryGameStatisticMessage) {
				if (exists playerStatistic, exists gameHistory) {
					return GameStatisticResponseMessage(playerStatistic.statistic, gameHistory.sequence());
				} else {
					return GameStatisticResponseMessage(PlayerStatistic(), []);
				}
			}
		}
	}
}