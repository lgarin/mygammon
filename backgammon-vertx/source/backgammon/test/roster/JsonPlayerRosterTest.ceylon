import backgammon.server.room {
	RoomConfiguration
}
import backgammon.server.roster {
	JsonPlayerRoster
}
import backgammon.shared {
	PlayerInfo,
	PlayerStatistic,
	PlayerStatisticOutputMessage,
	PlayerId,
	PlayerStatisticUpdateMessage,
	PlayerLoginMessage
}

import ceylon.file {
	parsePath,
	File,
	Nil
}
import ceylon.test {
	test
}

import java.lang {
	System
}

class JsonPlayerRepositoryTest() {
	
	value config = RoomConfiguration(null);
	value roster = JsonPlayerRoster(config);
	
	function createTempFile(String filename) {
		value path = parsePath(System.getProperty("java.io.tmpdir")).childPath("player-file.json");
		if (is File file = path.resource) {
			file.deleteOnExit();
		}
		return path;
	}
	
	test
	shared void readEmptyFile() {
		value result = roster.readData("source/backgammon/test/repository/empty-file.json");
		assert (result == 0);
	}
	
	test
	shared void readNonExistingFile() {
		value result = roster.readData("source/backgammon/test/repository/xxxx-file.json");
		assert (result == 0);
	}
	
	test
	shared void readExistingFile() {
		value result = roster.readData("source/backgammon/test/repository/player-file.json");
		assert (result == 1);
	}
	
	test
	shared void writeEmptyRepository() {
		value path = createTempFile("player-file.json");
		value result = roster.writeData(path.string);
		assert (result == 0);
	}
	
	test
	shared void overwriteWithEmptyRepository() {
		value path = createTempFile("new-player-file.json");
		assert (is Nil file = path.resource);
		file.createFile();
		value result = roster.writeData(path.string);
		assert (result == 0);
	}
	
	test
	shared void updateNewPlayer() {
		value info = PlayerInfo("123", "test");
		value stat = PlayerStatistic(100, 1, 1, 10);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(info, stat));
		assert (is PlayerStatisticOutputMessage result);
		assert (result.playerId == info.playerId);
		assert (result.statistic == stat);
	}
	
	test
	shared void storeNewPlayerTwice() {
		value info = PlayerInfo("123", "test");
		value stat = PlayerStatistic(100, 1, 1, 10);
		roster.processInputMessage(PlayerStatisticUpdateMessage(info, stat));
		value stat2 = PlayerStatistic(200, 2, 2, 20);
		value result = roster.processInputMessage(PlayerStatisticUpdateMessage(info, stat2));
		assert (is PlayerStatisticOutputMessage result);
		assert (result.playerId == info.playerId);
		assert (result.statistic == stat2);
	}
	
	test
	shared void retrieveExistingPlayer() {
		value info = PlayerInfo("123", "test");
		value stat = PlayerStatistic(100, 1, 1, 10);
		roster.processInputMessage(PlayerLoginMessage(info));
		value id = PlayerId("123");
		value result = roster.processInputMessage(PlayerLoginMessage(info));
		assert (is PlayerStatisticOutputMessage result);
		assert (result.playerId == id);
		assert (result.statistic == PlayerStatistic(100, 1, 1, 10));
	}
	
	test
	shared void retrieveNonExistingPlayer() {
		value info = PlayerInfo("123", "test");
		value id = PlayerId("124");
		value result = roster.processInputMessage(PlayerLoginMessage(info));
		assert (is PlayerStatisticOutputMessage result);
		assert (result.playerId == id);
		assert (result.statistic == PlayerStatistic(config.initialPlayerBalance));
	}
}