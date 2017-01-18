import backgammon.shared {
	PlayerState,
	PlayerListMessage,
	TableId,
	PlayerId,
	PlayerInfo,
	PlayerStatistic
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
		return Object {"id" -> state.info.id, "name" -> state.info.name, "buttonClass" -> buttonClass, "tableId" -> state.tableId?.toJson(), "iconUrl" -> state.info.iconUrl, "pictureUrl" -> state.info.pictureUrl, "score" -> state.statistic.score, "win" -> state.statistic.winPercentage, "lost" -> state.statistic.lostPercentage, "games" -> state.statistic.playedGames, "balance" -> state.statistic.balance};
	}
	
	shared TableId? findTable(PlayerId playerId) {
		if (exists playerState = playerMap[playerId]) {
			return playerState.tableId;
		} else {
			return null;
		}
	}
	
	function comparePlayer(PlayerState first, PlayerState second) => first.statistic.score.compare(second.statistic.score);
	
	shared PlayerState? findPlayer(PlayerId playerId) => playerMap[playerId];
	
 	shared Array toTemplateData(Boolean hideButtons) => Array(playerMap.items.sort(comparePlayer).map(toRowData(hideButtons)));
	
	shared Boolean empty => playerMap.empty;
	
	shared void updatePlayer(PlayerInfo? playerInfo) {
		if (exists playerInfo, !playerMap.defines(playerInfo.playerId)) {
			playerMap.put(playerInfo.playerId, PlayerState(playerInfo, PlayerStatistic(0), null, null)); 
		}
	}
	
	shared void updateTable(PlayerId playerId, TableId? tableId) {
		if (exists player = findPlayer(playerId)) {
			playerMap.put(playerId, player.withTable(tableId));
		}
	} 
}