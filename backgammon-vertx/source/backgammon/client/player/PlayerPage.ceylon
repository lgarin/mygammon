import backgammon.client {
	TablePage
}
import backgammon.client.browser {
	window,
	HTMLElement,
	document
}
import backgammon.shared {
	RoomId,
	OutboundRoomMessage,
	StatusResponseMessage,
	OutboundTableMessage,
	TableStateResponseMessage,
	LeaveTableMessage,
	TableId,
	JoinTableMessage,
	PlayerStateRequestMessage,
	CreatedMatchMessage,
	JoinedTableMessage,
	LeftTableMessage,
	PlayerState,
	PlayerStateMessage,
	OutboundScoreBoardMessage,
	ScoreBoardResponseMessage,
	GameStatisticResponseMessage,
	PlayerId,
	QueryGameStatisticMessage
}

shared final class PlayerPage() extends TablePage<PlayerGui>(PlayerGui(document)) {
	variable RoomId? roomId = null;
	variable PlayerId? queryPlayerId = null;
	variable PlayerState? currentPlayerState = null;
	
	function extractRoomId() {
		if (!roomId exists) {
			if (exists id = splitString(window.location.href, "/room/", "/player")) {
				roomId = RoomId(id);
			}
		}
		return roomId;
	}
	
	function extractQueryPlayerId() {
		if (!queryPlayerId exists) {
			if (exists id = splitString(window.location.href, "/player?id=")) {
				queryPlayerId = PlayerId(id);
			}
		}
		return queryPlayerId;
	}
	
	isBoardPreview() => true;

	shared actual Boolean onButton(HTMLElement target) {
		
		if (super.onButton(target)) {
			return true;
		} else if (target.id == gui.homeButtonId, exists roomId = extractRoomId()) {
			window.location.\iassign("/room/``roomId``");
			return true;
		} else if (target.id == gui.playButtonId, exists roomId = extractRoomId()) {
			window.location.\iassign("/room/``roomId``/play");
			return true;
		} else if (target.id == gui.leaveButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-leave");
				return true;
			} else {
				return onLeaveConfirmed();
			}
		} else if (target.id == gui.joinButtonId, exists currentRoomId = extractRoomId(), exists tableId = tableClient?.tableId) {
			gameCommander(JoinTableMessage(currentPlayerId, tableId));
			return true;
		} else if (target.id == gui.accountButtonId, exists roomId = extractRoomId()) {
			window.location.\iassign("/room/``roomId``/account");
			return true;
		} else {
			return false;
		}
	}

	function showTable(TableId newTableId) {
		gui.showTableInfo(newTableId, currentPlayerState);
		
		if (exists currentTableClient = tableClient, currentTableClient.tableId == newTableId) {
			return true;
		}
		
		eventBusClient.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
		eventBusClient.removeAddresses((a) => a.startsWith("OutboundTableMessage-"));
		
		gui.showInitialGame();
		openTableClient(newTableId);
		gui.showTablePreview();
		return true;
	}

	
	void hideTable() {
		closeTableClient();
		gui.hideTablePreview();
	}

	
	shared Boolean onLeaveConfirmed() {
		
		if (exists playerState = currentPlayerState, exists tableId = playerState.tableId) {
			gameCommander(LeaveTableMessage(currentPlayerId, tableId));
			return true;
		} else {
			// player is only viewing the table
			return true;
		}
	}
	
	shared Boolean onAcceptMatch() {
		
		if (exists currentTableClient = tableClient) {
			window.location.\iassign("/room/``currentTableClient.tableId.roomId``/table/``currentTableClient.tableId.table``/play");
			return true;
		} else {
			return false;
		}
	}

	shared actual Boolean handleRoomMessage(OutboundRoomMessage message) {
		
		if (!message.success) {
			window.location.reload();
			return true;
		}
		
		if (is PlayerStateMessage message) {
			if (exists state = message.state) {
				login(state, message.roomId);
				return true;
			} else {
				return false;
			}
		} else {
			return true;
		}
	}
	
	shared actual Boolean handleTableMessage(OutboundTableMessage message) {
		
		if (is StatusResponseMessage message, !message.success) {
			window.location.reload();
			return true;
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			// TODO some changes may occur on the state between the response and the registration
			eventBusClient.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
			eventBusClient.addAddress("OutboundGameMessage-``currentMatch.id``");
		} else if (is CreatedMatchMessage message) {
			eventBusClient.removeAddresses((a) => a.startsWith("OutboundGameMessage-"));
			eventBusClient.addAddress("OutboundGameMessage-``message.matchId``");
			if (message.hasPlayer(currentPlayerId)) {
				gui.showDialog("dialog-accept");
			}
		} else if (is JoinedTableMessage message, message.playerId == currentPlayerId) {
			showTable(message.tableId);
		} else if (is LeftTableMessage message, message.playerId == currentPlayerId) {
			hideTable();
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleTableMessage(message);
		} else {
			return false;
		}
	}

	shared actual Boolean handleScoreMessage(OutboundScoreBoardMessage message) {
		switch (message)
		case (is ScoreBoardResponseMessage) {
			return false;
		}
		case (is GameStatisticResponseMessage) {
			gui.showPlayer(message.playerInfo, message.playerStatistic);
			if (exists roomId = extractRoomId(), exists queryPlayerId = extractQueryPlayerId()) {
				gui.showGames(roomId, queryPlayerId, message.gameHistory);
				return true;
			} else {
				return false;
			}
		}
	}

	void login(PlayerState playerState, RoomId currentRoomId) {
		print(playerState.toJson());
		currentPlayerState = playerState; 
		eventBusClient.addAddress("OutboundRoomMessage-``currentRoomId``");
		gui.showBeginState(playerState);
		if (exists queryPlayerId = extractQueryPlayerId()) {
			scoreCommander(QueryGameStatisticMessage(queryPlayerId));
		} else {
			scoreCommander(QueryGameStatisticMessage(playerState.playerId));
		}
		if (exists tableId = playerState.tableId) {
			showTable(tableId);
		}
	}
	
	shared void run() {
		if (exists currentRoomId = extractRoomId(), exists currentPlayerId = extractPlayerId()) {
			roomCommander(PlayerStateRequestMessage(currentPlayerId, currentRoomId));
		} else {
			restart();
		}
	}
}