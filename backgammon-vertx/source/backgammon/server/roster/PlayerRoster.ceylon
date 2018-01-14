import backgammon.server.room {
	RoomConfiguration
}
import backgammon.server.util {
	ObtainableLock
}
import backgammon.shared {
	InboundPlayerRosterMessage,
	OutboundPlayerRosterMessage,
	PlayerId,
	PlayerStatistic,
	PlayerStatisticOutputMessage,
	PlayerLoginMessage,
	PlayerStatisticUpdateMessage,
	PlayerInfo,
	PlayerDetailRequestMessage,
	PlayerDetailOutputMessage
}

import ceylon.collection {
	HashMap
}
import ceylon.time {
	Instant
}
shared final class PlayerRoster(RoomConfiguration config, Anything(InboundPlayerRosterMessage) recordUpdate) {
	
	value statisticMap = HashMap<PlayerId, PlayerRosterRecord>();
	value lock = ObtainableLock("PlayerRoster");

	function storeRecord(PlayerRosterRecord record, [PlayerInfo,PlayerStatistic]? loginDelta = null) {
		statisticMap.put(record.id, record);
		return PlayerStatisticOutputMessage(record.id, record.stat);
	}
	
	function storeRecordWithLoginDelta(PlayerRosterRecord record, PlayerInfo playerInfo, PlayerStatistic loginDelta) {
		statisticMap.put(record.id, record);
		recordUpdate(PlayerStatisticUpdateMessage(playerInfo, loginDelta));
		return PlayerStatisticOutputMessage(record.id, record.stat + loginDelta);
	}
	
	function initialLogin(PlayerInfo playerInfo, Instant timestamp)
			=> PlayerLogin(playerInfo.name, 1, timestamp, timestamp.plus(config.balanceIncreaseDelay));
	
	function updatePlayerStatistic(PlayerStatisticUpdateMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value record = PlayerRosterRecord(oldRecord.id, oldRecord.login, oldRecord.stat + message.statisticDelta);
			return storeRecord(record);
		} else {
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, message.timestamp), message.statisticDelta);
			return storeRecord(record);
		}
	}

	function loginPlayer(PlayerLoginMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value newLogin = oldRecord.login.renew(message.timestamp, config.balanceIncreaseDelay);
			if (oldRecord.login.mustCredit(message.timestamp)) {
				value loginDelta = PlayerStatistic(config.balanceIncreaseAmount);
				value record = PlayerRosterRecord(oldRecord.id, newLogin, oldRecord.stat);
				return storeRecordWithLoginDelta(record, message.playerInfo, loginDelta);
			} else {
				value record = PlayerRosterRecord(oldRecord.id, newLogin, oldRecord.stat);
				return storeRecord(record);
			}
		} else {
			value record = PlayerRosterRecord(message.playerId, initialLogin(message.playerInfo, message.timestamp), PlayerStatistic());
			value loginDelta = PlayerStatistic(config.initialPlayerBalance);
			return storeRecordWithLoginDelta(record, message.playerInfo, loginDelta);
		}
	}
	
	// TODO cleanup later
	function readStatistics(PlayerDetailRequestMessage message) {
		if (exists record = statisticMap[message.playerId]) {
			return PlayerDetailOutputMessage(PlayerInfo(record.id.string, record.login.name), record.stat, []);
		} else {
			return PlayerDetailOutputMessage(PlayerInfo(message.playerId.string, ""), PlayerStatistic(), []);
		}
	}
	
	shared OutboundPlayerRosterMessage processInputMessage(InboundPlayerRosterMessage message) {
		try (lock) {
			switch (message)
			case (is PlayerStatisticUpdateMessage) {
				return updatePlayerStatistic(message);
			}
			case (is PlayerLoginMessage) {
				return loginPlayer(message);
			}
			case (is PlayerDetailRequestMessage) {
				return readStatistics(message);
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