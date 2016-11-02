import backgammon.client.board {

	BoardPage
}
import backgammon.client.room {

	RoomPage
}

shared BoardPage createBoard() {
	value board = BoardPage();
	board.run();
	return board;
}

shared RoomPage createRoom() {
	value room = RoomPage();
	room.run();
	return room;
}