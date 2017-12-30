import ceylon.test {

	test
}
import backgammon.server.roster {

	PlayerRoster
}
import backgammon.server.room {

	RoomConfiguration
}
import backgammon.shared {

	PlayerStatisticUpdateMessage,
	PlayerInfo,
	PlayerStatistic,
	PlayerStatisticOutputMessage,
	PlayerLoginMessage
}
class PlayerRosterTest() {
	
	value playerInfo = PlayerInfo("id", "name");
	value configuration = RoomConfiguration(null);
	value roster = PlayerRoster(configuration);
	
	test
	shared void loginNewPlayer() {
		value result = roster.processInputMessage(PlayerLoginMessage(playerInfo));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == PlayerStatistic(configuration.initialPlayerBalance));
	}
	
	test
	shared void loginKnownPlayer() {
		roster.processInputMessage(PlayerLoginMessage(playerInfo));
		value result = roster.processInputMessage(PlayerLoginMessage(playerInfo));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == PlayerStatistic(configuration.initialPlayerBalance));
	}
	
	test
	shared void updateStatisticForKnownPlayer() {
		roster.processInputMessage(PlayerLoginMessage(playerInfo));
		value newStatistic = PlayerStatistic(2000, 1, 1, 100);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(playerInfo, newStatistic));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == newStatistic);
	}
	
	test
	shared void updateStatisticForUnknownPlayer() {
		value newStatistic = PlayerStatistic(2000, 1, 1, 100);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(playerInfo, newStatistic));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == newStatistic);
	}
}