import backgammon.shared {
	PlayerState,
	PlayerListMessage,
	TableId
}

import ceylon.collection {
	HashMap,
	linked
}
import ceylon.json {
	Array,
	Object
}

class PlayerListModel() {

	value playerMap = HashMap<String, PlayerState>(linked);
	
	shared void update(PlayerListMessage message) {
		playerMap.removeAll({for (p in message.oldPlayers) p.id});
		playerMap.putAll({for (p in message.newPlayers) p.id -> p});
		playerMap.putAll({for (p in message.updatedPlayers) p.id -> p});
	}
	
	function toRowData(PlayerState state) {
		return Object({"id" -> state.id, "name" -> state.name, "tableId" -> state.tableId?.toJson(), "iconUrl" -> state.iconUrl, "score" -> state.statistic.score, "win" -> state.statistic.winPercentage});
	}
	
	shared TableId? findTable(String playerId) {
		if (exists playerState = playerMap[playerId]) {
			return playerState.tableId;
		}
		return null;
	}
	
 	shared String toTemplateData() {
		if (playerMap.empty) {
			return Object().string;
		}
		return Array(playerMap.items.map(toRowData)).string;
	}
	
	shared Boolean empty => playerMap.empty;
}