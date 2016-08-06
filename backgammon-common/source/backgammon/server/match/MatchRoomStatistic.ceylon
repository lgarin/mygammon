import backgammon.common {

	RoomId
}
shared final class MatchRoomStatistic(shared RoomId roomId, shared Integer activePlayerCount, shared Integer totalPlayerCount, shared Integer freeTableCount, shared Integer busyTableCount) {
	string => "players:``activePlayerCount``/``totalPlayerCount`` tables:``busyTableCount``/``busyTableCount + freeTableCount``";
}