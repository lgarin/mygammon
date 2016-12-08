import backgammon.shared {
	PlayerState,
	PlayerListMessage,
	TableId,
	PlayerId,
	PlayerInfo
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

	value playerMap = HashMap<PlayerId, PlayerState>(linked);
	
	shared void update(PlayerListMessage message) {
		playerMap.removeAll({for (p in message.oldPlayers) p.playerId});
		playerMap.putAll({for (p in message.newPlayers) p.playerId -> p});
		playerMap.putAll({for (p in message.updatedPlayers) p.playerId -> p});
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
		return Object {"id" -> state.id, "name" -> state.name, "buttonClass" -> buttonClass, "tableId" -> state.tableId?.toJson(), "iconUrl" -> state.iconUrl, "score" -> state.statistic.score, "win" -> state.statistic.winPercentage};
	}
	
	shared TableId? findTable(PlayerId playerId) {
		if (exists playerState = playerMap[playerId]) {
			return playerState.tableId;
		} else {
			return null;
		}
	}
	
	shared PlayerState? findPlayer(PlayerId playerId) => playerMap[playerId];
	
 	shared String toTemplateData(Boolean hideButtons) {
		if (playerMap.empty) {
			return Object().string;
		} else {
			return Array(playerMap.items.map(toRowData(hideButtons))).string;
		}
	}
	
	shared Boolean empty => playerMap.empty;
	
	shared void updatePlayer(PlayerInfo? playerInfo) {
		if (exists playerInfo, !playerMap.defines(playerInfo.playerId)) {
			playerMap.put(playerInfo.playerId, playerInfo.toInitialPlayerState()); 
		}
	}
	
	shared void updateTable(PlayerId playerId, TableId? tableId) {
		if (exists player = findPlayer(playerId)) {
			playerMap.put(playerId, player.withTable(tableId));
		}
	} 
}