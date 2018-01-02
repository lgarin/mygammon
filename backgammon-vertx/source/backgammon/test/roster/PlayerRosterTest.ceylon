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
import ceylon.time {

	Instant,
	Duration
}
class PlayerRosterTest() {
	
	value baseTimestamp = Instant(0);
	value playerInfo = PlayerInfo("id", "name");
	value configuration = RoomConfiguration(null);
	value roster = PlayerRoster(configuration);
	
	test
	shared void loginNewPlayer() {
		value result = roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == PlayerStatistic(configuration.initialPlayerBalance));
	}
	
	test
	shared void loginKnownPlayer() {
		roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp));
		value result = roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp.plus(Duration(1))));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == PlayerStatistic(configuration.initialPlayerBalance));
	}
	
	test
	shared void loginPlayerForFreeCredit() {
		roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp));
		value result = roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp.plus(configuration.balanceIncreaseDelay)));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == PlayerStatistic(configuration.initialPlayerBalance + configuration.balanceIncreaseAmount));
	}
	
	test
	shared void updateStatisticForKnownPlayer() {
		roster.processInputMessage(PlayerLoginMessage(playerInfo, baseTimestamp));
		value delta = PlayerStatistic(2000, 1, 1, 100);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(playerInfo, delta, baseTimestamp.plus(Duration(1))));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == delta + PlayerStatistic(configuration.initialPlayerBalance));
	}
	
	test
	shared void updateStatisticForUnknownPlayer() {
		value delta = PlayerStatistic(2000, 1, 1, 100);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(playerInfo, delta, baseTimestamp));
		assert (result.playerId == playerInfo.playerId);
		assert (is PlayerStatisticOutputMessage result);
		assert (result.statistic == delta);
	}
}