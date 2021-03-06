import backgammon.client {
	TablePage
}
import backgammon.client.browser {
	HTMLElement,
	window,
	document
}
import backgammon.shared {
	LeaveTableMessage,
	TableId,
	OutboundTableMessage,
	CreatedMatchMessage,
	TableStateResponseMessage,
	JoinTableMessage,
	JoinedTableMessage,
	LeftTableMessage,
	PlayerStateRequestMessage,
	OutboundRoomMessage,
	PlayerStateMessage,
	PlayerState,
	RoomId
}

shared final class BoardPage() extends TablePage<BoardGui>(BoardGui(document)) {
	variable TableId? tableId = null;
	variable String? draggedElementStyle = null;
	
	function extractTableId() {
		if (!tableId exists) {
			value url = window.location.href;
			if (exists roomId = splitString(url, "/room/", "/table"), exists table = splitString(url, "id=", "&") else splitString(url, "id=")) {
				if (exists tableIndex = parseInteger(table)) {
					tableId = TableId(roomId, tableIndex);
				} 
			}
		}
		return tableId;
	}
	
	isBoardPreview() => window.location.href.endsWith("view");

	shared Boolean onStartDrag(HTMLElement source) {
		draggedElementStyle = source.getAttribute("style");
		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleStartDrag(source);
		} else {
			return false;
		}
	}
	
	shared Boolean onEndDrag(HTMLElement source) {
		// restore style
		if (exists style = draggedElementStyle) {
			source.setAttribute("style", style);
		}
		gui.hidePossibleMoves();
		return true;
	}
	
	shared Boolean onDrop(HTMLElement target, HTMLElement source) {

		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleDrop(target, source);
		} else {
			return false;
		}
	}
	
	shared actual Boolean onButton(HTMLElement target) {
		if (super.onButton(target)) {
			return true;
		} else if (target.id == gui.homeButtonId, exists tableId = extractTableId()) {
			window.location.\iassign("/room/``tableId.roomId``");
			return true;
		} else if (target.id == gui.joinButtonId, exists tableId = extractTableId()) {
			gameCommander(JoinTableMessage(currentPlayerId, tableId));
			return true;
		} else if (target.id == gui.leaveButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-leave");
				return true;
			} else {
				return onLeaveConfirmed();
			}
		} else if (target.id == gui.accountButtonId, exists tableId = extractTableId()) {
			window.location.\iassign("/room/``tableId.roomId``/account");
			return true;
		}
		
		return false;
	}
	
	shared Boolean onJokerConfirmed(HTMLElement target) {
		if (target.id == gui.jokerControlRollId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleControlRollEvent();
		} else if (target.id == gui.jokerTakeTurnId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleTakeTurnEvent();
		} else {
			return false;
		}
	}
	
	shared Boolean onChecker(HTMLElement checker) {

		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleCheckerSelection(checker);
		} else {
			return false;
		}
	}

	shared Boolean onLeaveConfirmed() {

		if (exists currentTableClient = tableClient) {
			gameCommander(LeaveTableMessage(currentPlayerId, currentTableClient.tableId));
			return true;
		} else {
			return false;
		}
	}

	shared Boolean onPlayAgain() {
		if (exists tableId = extractTableId()) {
			window.location.\iassign("/room/``tableId.roomId``/play");
			return true;
		}
		return false;
	}
	
	shared Boolean onStopPlay() {
		if (exists tableId = extractTableId()) {
			window.location.\iassign("/room/``tableId.roomId``");
			return true;
		}
		return false;
	}
	
	shared actual Boolean handleRoomMessage(OutboundRoomMessage message) {
		
		if (!super.handleRoomMessage(message)) {
			return false;
		} else if (is PlayerStateMessage message) {
			if (exists state = message.state, exists currentTableId = extractTableId()) {
				login(state, currentTableId);
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleTableMessage(OutboundTableMessage message) {

		if (!super.handleTableMessage(message)) {
			return false;
		} else if (is TableStateResponseMessage message) {
			if (message.isPlayerInQueue(currentPlayerId)) {
				gui.hideJoinButton();
				gui.showLeaveButton();
			} else {
				gui.hideLeaveButton();
				gui.showJoinButton();
			}
		} else if (is JoinedTableMessage message, message.playerId == currentPlayerId) {
			window.location.\iassign("/room/``message.tableId.roomId``/table?id=``message.tableId.table``&action=play");
		} else if (is LeftTableMessage message, message.playerId == currentPlayerId) {
			gui.hideLeaveButton();
			gui.showJoinButton();
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			if (currentMatch.hasPlayer(currentPlayerId) && isBoardPreview()) {
				window.location.\iassign("/room/``message.tableId.roomId``/table?id=``message.tableId.table``&action=play");
			} else {
				// TODO some changes may occur on the state between the response and the registration
				eventBusClient.addAddress("OutboundGameMessage-``currentMatch.id``");
			}
		} else if (is CreatedMatchMessage message) {
			if (message.hasPlayer(currentPlayerId) && isBoardPreview()) {
				window.location.\iassign("/room/``message.tableId.roomId``/table?id=``message.tableId.table``&action=play");
			} else {
				eventBusClient.addAddress("OutboundGameMessage-``message.matchId``");
			}
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleTableMessage(message);
		} else {
			return false;
		}
	}
	
	

	void login(PlayerState playerState, TableId tableId) {
		print(playerState.toJson());
		openTableClient(tableId);
		gui.showBeginState(playerState);
	}
	
	shared void run() {
		if (exists currentTableId = extractTableId(), exists currentPlayerId = extractPlayerId()) {
			roomCommander(PlayerStateRequestMessage(currentPlayerId, RoomId(currentTableId.roomId)));
		} else {
			restart();
		}
	}
}