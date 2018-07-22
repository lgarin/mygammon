import backgammon.shared.game {
	GameConfiguration
}
import ceylon.json {
	Object
}
import ceylon.time {

	Duration
}

shared class RoomConfiguration(Object? json) extends GameConfiguration(json) {
	shared String roomId = json?.getStringOrNull("roomId") else "test";
	shared Integer initialPlayerBalance = json?.getIntegerOrNull("initialPlayerBalance") else 1000;
	shared Integer playerBet = json?.getIntegerOrNull("playerBet") else 110;
	shared Integer matchPot = json?.getIntegerOrNull("matchPot") else 200;
	shared Integer bonusScorePercentage = json?.getIntegerOrNull("bonusScorePercentage") else 5;
	shared Integer maxTableCount = json?.getIntegerOrNull("maxTableCount") else 10;
	shared Integer maxPlayerCount = json?.getIntegerOrNull("maxPlayerCount") else 100;
	shared Integer gameThreadCount = json?.getIntegerOrNull("gameThreadCount") else 4;
	shared Integer maxPlayerMessageRate = json?.getIntegerOrNull("maxPlayerMessageRate") else 10;
	shared Duration balanceIncreaseDelay = Duration(json?.getIntegerOrNull("balanceIncreaseDelay") else 24 * 60 * 60 * 1000);
	shared Integer balanceIncreaseAmount = json?.getIntegerOrNull("balanceIncreaseAmount") else initialPlayerBalance / 2;
	shared [Integer*] scoreLevels = (json?.getArrayOrNull("scoreLevels") else [100, 250, 500, 1000, 2000, 5000]).narrow<Integer>().sequence();
	shared RoomSize roomSize => RoomSize(maxTableCount, maxPlayerCount);
	shared MatchBet matchBet => MatchBet(playerBet, matchPot);
	shared Duration chatMessageRetention = Duration(json?.getIntegerOrNull("chatMessageRetention") else 1 * 60 * 60 * 1000);
}
