import backgammon.shared {
	PlayerRepositoryInputMessage,
	PlayerRepositoryOutputMessage,
	PlayerId,
	PlayerStatistic,
	parsePlayerStatistic,
	parsePlayerId,
	PlayerRepositoryRetrieveMessage,
	PlayerRepositoryStoreMessage,
	PlayerStatisticStoreMessage,
	PlayerStatisticRetrieveMessage,
	PlayerStatisticOutputMessage
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
import backgammon.server.util {

	ObtainableLock
}
shared final class JsonPlayerRepository() {
	
	
	final class PlayerIdAndName(shared String id, shared String name) {}
	
	value statisticMap = HashMap<PlayerId, [PlayerIdAndName, PlayerStatistic]>();
	value lock = ObtainableLock();
	
	function readWholeFile(String path) {
		if (is File file = current.childPath(path).resource) {
			return lines(file).reduce((String partial, String element) => partial + element);
		} else {
			return null;
		}
	}
	
	function processPlayerStatisticStoreMessage(PlayerStatisticStoreMessage message) {
		statisticMap.put(message.key, [PlayerIdAndName(message.info.id, message.info.name), message.statistic]);
		return PlayerStatisticOutputMessage(message.key, message.statistic);
	}
	
	shared PlayerRepositoryOutputMessage processInputMessage(PlayerRepositoryInputMessage message) {
		try (lock) {
			switch (message)
			case (is PlayerStatisticStoreMessage) {
				return processPlayerStatisticStoreMessage(message);
			}
			case (is PlayerStatisticRetrieveMessage) {
				return nothing;
			}
		}
	}
	
	function parseStatisticEntry(Object json) => parsePlayerId(json.getString("id")) -> [PlayerIdAndName(json.getString("id"), json.getString("name")), parsePlayerStatistic(json.getObject("stat"))];
	
	shared Integer readData(String filepath) {
		try (lock) {
			statisticMap.clear();
			if (exists content = readWholeFile(filepath)) {
				assert (is Array data = parse(content));
				statisticMap.putAll(data.narrow<Object>().map(parseStatisticEntry));
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
	
	function formatStatisticRecord([PlayerIdAndName, PlayerStatistic] entry) => Object {"id" -> entry[0].id, "name" -> entry[0].name, "stat" -> entry[1].toJson()};
	
	void writeStatisticMap(Writer writer) {
		writer.writeLine("[");
		for (entry in statisticMap.items.map(formatStatisticRecord)) {
			writer.write(entry.string);
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
}