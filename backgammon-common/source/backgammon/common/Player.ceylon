shared interface Player {

	shared formal String id;

	shared formal Boolean leaveRoom();
	shared formal Boolean leaveTable();
	shared formal Boolean joinFreeTable();	
}

class PlayerImpl(shared actual String id, shared Anything(PlayerMessage) messageListener, variable RoomImpl? room = null) satisfies Player {
	variable TableImpl? table = null;
	variable GameImpl? game = null;
	
	shared actual Boolean leaveRoom() {
		leaveTable();
		if (exists currentRoom = room) {
			currentRoom.removePlayer(this);
			room = null;
			return true;
		} else {
			return false;
		}
	}
	
	shared actual Boolean leaveTable() {
		leaveGame();
		
		if (exists currentTable = table) {
			assert (exists currentRoom = room);
			currentTable.removePlayer(this);
			currentRoom.enqueueFreeTable(currentTable);
			table = null;
			messageListener(LeaftTableMessage(this, currentTable));
			return true;
		} else {
			return false;
		}
	}
	
	shared actual Boolean joinFreeTable() {
		leaveTable();
		
		if (exists currentRoom = room) {
			return currentRoom.sitPlayer(this);
		} else {
			return false;
		}
	}
	
	shared void joinTable(TableImpl currentTable) {
		leaveTable();
		
		table = currentTable;
		messageListener(JoinedTableMessage(this, currentTable));
		currentTable.sitPlayer(this);
	}
	
	shared Boolean leaveGame() {
		
		if (exists currentGame = game) {
			currentGame.removePlayer(this);
			return true;
		} else {
			return false;
		}
	}
	
	shared void joinGame(GameImpl currentGame) {
		leaveGame();
		
		game = currentGame;
		messageListener(JoiningGameMessage(this, currentGame));
	}
	
	shared void waitOpponent() {
		if (exists currentTable = table) {
			messageListener(WaitingOpponentMessage(this, currentTable));
		}
	}
}