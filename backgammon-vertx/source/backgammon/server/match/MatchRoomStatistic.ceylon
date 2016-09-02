import backgammon.shared {
	RoomId
}

shared final class MatchRoomStatistic(
		shared RoomId roomId,
		shared Integer activePlayerCount, shared Integer maxPlayerCount, shared Integer totalPlayerCount,
		shared Integer freeTableCount, shared Integer maxTableCount, shared Integer busyTableCount, 
		shared Integer activeMatchCount, shared Integer maxMatchCount, shared Integer totalMatchCount) {
	
	value players = "players:``activePlayerCount``/``maxPlayerCount``/``totalPlayerCount``";
	value tables = "tables:``busyTableCount``/``maxTableCount``/``busyTableCount + freeTableCount``";
	value matches = "matches:``activeMatchCount``/``maxMatchCount``/``totalMatchCount``";
	
	string = "``players`` ``tables`` ``matches``";
}