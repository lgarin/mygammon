
import backgammon.shared {

	RoomId
}

shared final class GameRoomStatistic(shared RoomId roomId, shared Integer activeGameCount, shared Integer totalGameCount) {
	string => "games:``activeGameCount``/``totalGameCount``";
}