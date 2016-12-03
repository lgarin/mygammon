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

class PlayerListModel(String hiddenClass) {

	value playerMap = HashMap<String, PlayerState>(linked);
	
	shared void update(PlayerListMessage message) {
		playerMap.removeAll({for (p in message.oldPlayers) p.id});
		playerMap.putAll({for (p in message.newPlayers) p.id -> p});
		playerMap.putAll({for (p in message.updatedPlayers) p.id -> p});
	}
	
	function toRowData(Boolean hideButtons)(PlayerState state) {
		
		String buttonClass;
		if (hideButtons && state.tableId exists) {
			buttonClass = "disabled";
		} else if (state.tableId exists) {
			buttonClass = "";
		} else {
			buttonClass = hiddenClass;
		}
		return Object({"id" -> state.id, "name" -> state.name, "buttonClass" -> buttonClass, "tableId" -> state.tableId?.toJson(), "iconUrl" -> state.iconUrl, "score" -> state.statistic.score, "win" -> state.statistic.winPercentage});
	}
	
	shared TableId? findTable(String playerId) {
		if (exists playerState = playerMap[playerId]) {
			return playerState.tableId;
		}
		return null;
	}
	
	shared PlayerState? findPlayer(String playerId) => playerMap[playerId];
	
 	shared String toTemplateData(Boolean hideButtons) {
		if (playerMap.empty) {
			return Object().string;
		}
		return Array(playerMap.items.map(toRowData(hideButtons))).string;
	}
	
	shared Boolean empty => playerMap.empty;
}