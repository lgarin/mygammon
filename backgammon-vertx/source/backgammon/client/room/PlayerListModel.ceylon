import backgammon.shared {
	PlayerState,
	PlayerListMessage,
	TableId,
	PlayerId,
	PlayerInfo,
	PlayerStatistic,
	RoomId
}

import ceylon.collection {
	HashMap,
	linked
}
import ceylon.json {
	JsonObject,
	JsonArray
}

final class PlayerListModel(String hiddenClass) {

	value playerMap = HashMap<PlayerId, PlayerState>(linked);
	
	shared void update(PlayerListMessage message) {
		playerMap.removeAll({for (p in message.oldPlayers) p.playerId});
		playerMap.putAll({for (p in message.newPlayers) p.playerId -> p});
		playerMap.putAll({for (p in message.updatedPlayers) p.playerId -> p});
	}
	
	function toRowData(RoomId roomId, Boolean hideButtons)(PlayerState state) {
		
		String buttonClass;
		if (hideButtons && state.tableId exists) {
			buttonClass = "disabled";
		} else if (state.tableId exists) {
			buttonClass = "";
		} else {
			buttonClass = hiddenClass;
		}
		value levelClass = if (exists level = state.info.level) then "player-level level-``level``" else "hidden";
		return JsonObject {"playerId" -> state.info.id, "name" -> state.info.name, "link" -> "/room/``roomId``/player?id=``state.info.id``", "viewButtonClass" -> buttonClass, "table" -> state.tableId?.table, "levelClass" -> levelClass, "score" -> state.statistic.score, "win" -> state.statistic.winPercentage, "games" -> state.statistic.playedGames };
	}
	
	shared TableId? findTable(PlayerId playerId) {
		if (exists playerState = playerMap[playerId]) {
			return playerState.tableId;
		} else {
			return null;
		}
	}
	
	shared PlayerState? findPlayer(PlayerId playerId) => playerMap[playerId];
	
 	shared JsonArray toTemplateData(RoomId roomId, Boolean hideButtons) => JsonArray(playerMap.items.map(toRowData(roomId, hideButtons)));
	
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