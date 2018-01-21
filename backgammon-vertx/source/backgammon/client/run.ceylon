import backgammon.client.board {

	BoardPage
}
import backgammon.client.account {

	AccountPage
}
import backgammon.client.room {

	RoomPage
}
import backgammon.client.player {

	PlayerPage
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

shared AccountPage createAccount() {
	value account = AccountPage();
	account.run();
	return account;
}

shared PlayerPage createPlayer() {
	value player = PlayerPage();
	player.run();
	return player;
}