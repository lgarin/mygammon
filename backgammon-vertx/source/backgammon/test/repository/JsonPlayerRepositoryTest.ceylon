import ceylon.test {
	test
}
import backgammon.server.repository {

	JsonPlayerRepository
}
import java.lang {

	System
}
import ceylon.file {

	parsePath,
	File,
	Nil
}
import backgammon.shared {

	PlayerStatisticStoreMessage,
	PlayerInfo,
	PlayerStatistic,
	PlayerStatisticOutputMessage
}

class JsonPlayerRepositoryTest() {
	
	value repository = JsonPlayerRepository();
	
	function createTempFile(String filename) {
		value path = parsePath(System.getProperty("java.io.tmpdir")).childPath("player-file.json");
		if (is File file = path.resource) {
			file.deleteOnExit();
		}
		return path;
	}
	
	test
	shared void readEmptyFile() {
		value result = repository.readData("source/backgammon/test/repository/empty-file.json");
		assert (result == 0);
	}
	
	test
	shared void readNonExistingFile() {
		value result = repository.readData("source/backgammon/test/repository/xxxx-file.json");
		assert (result == 0);
	}
	
	test
	shared void readExistingFile() {
		value result = repository.readData("source/backgammon/test/repository/player-file.json");
		assert (result == 1);
	}
	
	test
	shared void writeEmptyRepository() {
		value path = createTempFile("player-file.json");
		value result = repository.writeData(path.string);
		assert (result == 0);
	}
	
	test
	shared void overwriteWithEmptyRepository() {
		value path = createTempFile("new-player-file.json");
		assert (is Nil file = path.resource);
		file.createFile();
		value result = repository.writeData(path.string);
		assert (result == 0);
	}
	
	test
	shared void storeNewPlayer() {
		value info = PlayerInfo("123", "test");
		value stat = PlayerStatistic(100, 1, 1, 10);
		value result = repository.processInputMessage(PlayerStatisticStoreMessage(info, stat));
		assert (is PlayerStatisticOutputMessage result);
		assert (result.key == info.playerId);
		assert (result.statistic == stat);
	}
}