import backgammon.shared {
	RoomId
}

shared final class MatchRoomStatistic(shared RoomId roomId, shared Integer activePlayerCount, shared Integer totalPlayerCount, shared Integer freeTableCount, shared Integer busyTableCount, shared Integer activeMatchCount, shared Integer totalMatchCount) {
	string => "players:``activePlayerCount``/``totalPlayerCount`` tables:``busyTableCount``/``busyTableCount + freeTableCount`` matches:``activeMatchCount``/``totalMatchCount``";
}