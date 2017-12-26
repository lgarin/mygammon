import backgammon.shared {
	RoomId
}

shared final class MatchRoomStatistic(
		shared RoomId roomId,
		shared Integer activePlayerCount = 0, shared Integer maxPlayerCount = 0, shared Integer totalPlayerCount =  0,
		shared Integer busyTableCount = 0, shared Integer maxTableCount = 0, shared Integer totalTableCount = 0, 
		shared Integer activeMatchCount = 0, shared Integer maxMatchCount = 0, shared Integer totalMatchCount = 0) {
	
	value players = "players:``activePlayerCount``/``maxPlayerCount``/``totalPlayerCount``";
	value tables = "tables:``busyTableCount``/``maxTableCount``/``totalTableCount``";
	value matches = "matches:``activeMatchCount``/``maxMatchCount``/``totalMatchCount``";
	
	string = "``players`` ``tables`` ``matches``";
}