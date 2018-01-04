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
import ceylon.time {
	Instant
}
shared final class PlayerRoster(RoomConfiguration config) {
	
	value statisticMap = HashMap<PlayerId, PlayerRosterRecord>();
	value lock = ObtainableLock("PlayerRoster");

	function storeRecord(PlayerRosterRecord record) {
		statisticMap.put(record.id, record);
		return PlayerStatisticOutputMessage(record.id, record.stat);
	}
	
	function initialLogin(PlayerInfo playerInfo, Instant timestamp)
			=> PlayerLogin(playerInfo.name, 1, timestamp, timestamp.plus(config.balanceIncreaseDelay));
	
	function updatePlayerStatistic(PlayerStatisticUpdateMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value record = PlayerRosterRecord(oldRecord.id, oldRecord.login, oldRecord.stat + message.statistic);
			return storeRecord(record);
		} else {
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, message.timestamp), message.statistic);
			return storeRecord(record);
		}
	}

	function loginPlayer(PlayerLoginMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value newLogin = oldRecord.login.renew(message.timestamp, config.balanceIncreaseDelay);
			if (oldRecord.login.mustCredit(message.timestamp)) {
				value record = PlayerRosterRecord(oldRecord.id, newLogin, oldRecord.stat.updateBalance(config.balanceIncreaseAmount));
				return storeRecord(record);
			} else {
				value record = PlayerRosterRecord(oldRecord.id, newLogin, oldRecord.stat);
				return storeRecord(record);
			}
		} else {
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, message.timestamp), PlayerStatistic(config.initialPlayerBalance));
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