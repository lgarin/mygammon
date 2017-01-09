import backgammon.server.room {
	RoomConfiguration
}
import backgammon.server.util {
	ObtainableLock
}
import backgammon.shared {
	PlayerRosterInboundMessage,
	PlayerRosterOutboundMessage,
	PlayerId,
	PlayerStatistic,
	PlayerStatisticOutputMessage,
	PlayerLoginMessage,
	PlayerStatisticUpdateMessage,
	PlayerInfo
}

import ceylon.collection {
	HashMap
}
import ceylon.file {
	File,
	current,
	lines,
	Nil,
	Writer
}
import ceylon.json {
	Object,
	Array,
	parse
}
import ceylon.time {
	now,
	Instant
}
shared final class JsonPlayerRoster(RoomConfiguration config) {
	
	value statisticMap = HashMap<PlayerId, PlayerRosterRecord>();
	value lock = ObtainableLock();
	
	function readWholeFile(String path) {
		if (is File file = current.childPath(path).resource) {
			return lines(file).reduce((String partial, String element) => partial + element);
		} else {
			return null;
		}
	}
	
	function storeRecord(PlayerRosterRecord record) {
		statisticMap.put(record.id, record);
		return PlayerStatisticOutputMessage(record.id, record.stat);
	}
	
	function initialLogin(PlayerInfo playerInfo, Instant timestamp)
			=> PlayerLogin(playerInfo.name, 1, timestamp, timestamp.plus(config.balanceIncreaseDelay));
	
	function updatePlayerStatistic(PlayerStatisticUpdateMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value record = PlayerRosterRecord(oldRecord.id, oldRecord.login, message.statistic);
			return storeRecord(record);
		} else {
			value timestamp = now();
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, timestamp), message.statistic);
			return storeRecord(record);
		}
	}

	function loginPlayer(PlayerLoginMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value timestamp = now();
			if (oldRecord.login.mustCredit(timestamp, config.balanceIncreaseDelay)) {
				value record = PlayerRosterRecord(oldRecord.id, oldRecord.login.renew(timestamp, config.balanceIncreaseDelay), oldRecord.stat.updateBalance(config.balanceIncreaseAmount));
				return storeRecord(record);
			} else {
				value record = PlayerRosterRecord(oldRecord.id, oldRecord.login.renew(timestamp, config.balanceIncreaseDelay), oldRecord.stat);
				return storeRecord(record);
			}
		} else {
			value timestamp = now();
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, timestamp), PlayerStatistic(config.initialPlayerBalance));
			return storeRecord(record);
		}
	}
	
	shared PlayerRosterOutboundMessage processInputMessage(PlayerRosterInboundMessage message) {
		try (lock) {
			switch (message)
			case (is PlayerStatisticUpdateMessage) {
				return updatePlayerStatistic(message);
			}
			case (is PlayerLoginMessage) {
				return loginPlayer(message);
			}
		}
	}
	
	function makeRosterEntry(Object json) {
		value record = parsePlayerRosterRecord(json);
		return record.id -> record;
	}
	
	shared Integer readData(String filepath) {
		try (lock) {
			statisticMap.clear();
			if (exists content = readWholeFile(filepath)) {
				assert (is Array data = parse(content));
				statisticMap.putAll(data.narrow<Object>().map(makeRosterEntry));
			}
			return statisticMap.size;
		}
	}
	
	function createWriter(String filepath) {
		switch (file = current.childPath(filepath).resource)
		case (is File) {
			return file.Overwriter();
		}
		case (is Nil) {
			return file.createFile().Overwriter();
		}
		else {
			throw Exception("Path ``filepath`` does not denote a file");
		}
	}
	
	void writeStatisticMap(Writer writer) {
		writer.writeLine("[");
		for (record in statisticMap.items) {
			writer.write(record.toJson().string);
			writer.writeLine(",");
		}
		writer.writeLine("]");
	}
	
	shared Integer writeData(String filepath) {
		try (lock) {
			// TODO use try with resources
			value writer = createWriter(filepath);
			try {
				writeStatisticMap(writer);
			} finally {
				writer.close();
			}
			return statisticMap.size;
		}
	}
	
	shared PlayerRepositoryStatistic statistic {
		try (lock) {
			variable Integer gameCount = 0;
			variable Integer totalBalance = 0;
			variable Integer loginCount = 0;
			for (record in statisticMap.items) {
				gameCount += record.stat.playedGames;
				totalBalance += record.stat.balance;
				loginCount += record.login.count;
			}
			return PlayerRepositoryStatistic(statisticMap.size, loginCount, gameCount / 2, totalBalance);
		}
	}
}