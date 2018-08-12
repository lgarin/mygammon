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
	PlayerDetailOutputMessage,
	PlayerTransaction,
	PlayerStatisticRequestMessage,
	PlayerInfoRequestMessage,
	PlayerInfoOutputMessage
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
		return PlayerStatisticOutputMessage(record.playerInfo, record.stat);
	}
	
	function storeRecordWithLoginDelta(PlayerRosterRecord record, PlayerStatistic loginDelta) {
		statisticMap.put(record.id, record);
		recordUpdate(PlayerStatisticUpdateMessage(record.playerInfo, loginDelta));
		return PlayerStatisticOutputMessage(record.playerInfo, record.stat + loginDelta);
	}
	
	function initialLogin(Instant timestamp)
			=> PlayerLogin(1, timestamp, timestamp.plus(config.balanceIncreaseDelay));
	
	function updatePlayerStatistic(PlayerStatisticUpdateMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value record = PlayerRosterRecord(oldRecord.playerInfo, oldRecord.login, oldRecord.stat + message.statisticDelta);
			return storeRecord(record);
		} else {
			value record = PlayerRosterRecord(message.playerInfo, initialLogin(message.timestamp), message.statisticDelta);
			return storeRecord(record);
		}
	}

	function loginPlayer(PlayerLoginMessage message) {
		if (exists oldRecord = statisticMap[message.playerId]) {
			value playerLevel = oldRecord.stat.computeLevel(config.scoreLevels);
			value newLogin = oldRecord.login.renew(message.timestamp, config.balanceIncreaseDelay);
			if (oldRecord.login.mustCredit(message.timestamp)) {
				value loginDelta = PlayerStatistic(config.balanceIncreaseAmount);
				value record = PlayerRosterRecord(oldRecord.playerInfo.withLevel(playerLevel), newLogin, oldRecord.stat);
				return storeRecordWithLoginDelta(record, loginDelta);
			} else {
				value record = PlayerRosterRecord(oldRecord.playerInfo.withLevel(playerLevel), newLogin, oldRecord.stat);
				return storeRecord(record);
			}
		} else {
			value record = PlayerRosterRecord(message.playerInfo, initialLogin(message.timestamp), PlayerStatistic());
			value loginDelta = PlayerStatistic(config.initialPlayerBalance);
			return storeRecordWithLoginDelta(record, loginDelta);
		}
	}
	
	
	// TODO revisit later
	function playerTransactionType(PlayerStatisticUpdateMessage update) {
		if (update.isBet) {
			return "Bet";
		} else if (update.isWonGame) {
			return "Game won";
		} else if (update.isRefund) {
			return "Refund";
		} else if (update.isLogin) {
			return "Login";
		} else {
			return "Unknown";
		}
	}
	function toPlayerTransaction(PlayerStatisticUpdateMessage update) {
		return PlayerTransaction(playerTransactionType(update), update.statisticDelta.balance, update.timestamp);
	}

	
	function readDetails(PlayerDetailRequestMessage message, {InboundPlayerRosterMessage*} history) {
		if (exists record = statisticMap[message.playerId]) {
			value transactions = history.narrow<PlayerStatisticUpdateMessage>().filter(PlayerStatisticUpdateMessage.hasBalanceDelta).map(toPlayerTransaction);
			return PlayerDetailOutputMessage(record.playerInfo, record.stat, transactions.sequence());
		} else {
			return PlayerDetailOutputMessage(PlayerInfo(message.playerId.string, ""), PlayerStatistic(), []);
		}
	}
	
	function readStatistic(PlayerStatisticRequestMessage message) {
		if (exists record = statisticMap[message.playerId]) {
			return PlayerStatisticOutputMessage(record.playerInfo, record.stat);
		} else {
			return PlayerStatisticOutputMessage(PlayerInfo(message.playerId.string, ""), PlayerStatistic());
		}
	}
	
	function readInfos(PlayerInfoRequestMessage message) {
		return PlayerInfoOutputMessage([for (playerId in message.playerIds) statisticMap[message.playerId]?.playerInfo else PlayerInfo(playerId.id, "")]);
	}
	
	shared OutboundPlayerRosterMessage processInputMessage(InboundPlayerRosterMessage message, {InboundPlayerRosterMessage*} history = {}) {
		try (lock) {
			switch (message)
			case (is PlayerStatisticUpdateMessage) {
				return updatePlayerStatistic(message);
			}
			case (is PlayerLoginMessage) {
				return loginPlayer(message);
			}
			case (is PlayerDetailRequestMessage) {
				return readDetails(message, history);
			}
			case (is PlayerStatisticRequestMessage) {
				return readStatistic(message);
			}
			case (is PlayerInfoRequestMessage) {
				return readInfos(message);
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