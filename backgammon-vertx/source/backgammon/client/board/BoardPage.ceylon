import backgammon.client {
	BasePage,
	EventBusClient
}
import backgammon.client.browser {
	HTMLElement,
	window
}
import backgammon.shared {
	RoomResponseMessage,
	LeaveTableMessage,
	EndMatchMessage,
	formatRoomMessage,
	parseOutboundTableMessage,
	InboundGameMessage,
	MakeMoveMessage,
	parseOutboundMatchMessage,
	OutboundGameMessage,
	PlayerBeginMessage,
	GameStateRequestMessage,
	TableId,
	InboundMatchMessage,
	parseOutboundGameMessage,
	OutboundMatchMessage,
	MatchEndedMessage,
	InboundTableMessage,
	TableStateRequestMessage,
	UndoMovesMessage,
	OutboundTableMessage,
	StartGameMessage,
	EndGameMessage,
	CreatedMatchMessage,
	AcceptMatchMessage,
	TableStateResponseMessage,
	EndTurnMessage,
	JoinTableMessage,
	PlayerInfo,
	JoinedTableMessage,
	LeftTableMessage
}

import ceylon.json {
	Object
}
import ceylon.regex {
	regex
}
import ceylon.time {
	now
}
shared class BoardPage() extends BasePage() {
	variable TableId? tableId = null;
	value gui = BoardGui(window.document);
	variable TableClient? tableClient = null;
	variable String? draggedElementStyle = null;
	variable EventBusClient? tableEventClient = null;
	variable EventBusClient? gameEventClient = null;
	
	function extractTableId() {
		if (!tableId exists) {
			value match = regex("/room/(\\w+)/table/(\\d+)").find(window.location.href);
			if (exists match, exists roomId = match.groups[0], exists table = match.groups[1]) {
				if (exists tableIndex = parseInteger(table)) {
					tableId = TableId(roomId, tableIndex);
				} 
			}
		}
		return tableId;
	}
	
	function isPreview() => window.location.href.endsWith("view");
	
	void logout() {
		gameEventClient?.close();
		tableEventClient?.close();
		
		window.location.\iassign("/logout");
	}
	
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
	
	shared Boolean onButton(HTMLElement target) {
		if (target.id == gui.startButtonId) {
			window.location.\iassign("/start");
			return true;
		} else if (target.id == gui.homeButtonId, exists tableId = extractTableId()) {
			window.location.\iassign("/room/``tableId.roomId``");
			return true;
		} else if (target.id == gui.joinButtonId, exists tableId = extractTableId()) {
			gui.hideJoinButton();
			gameCommander(JoinTableMessage(currentPlayerId, tableId));
			return true;
		} else if (target.id == gui.leaveButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-leave");
				return true;
			} else {
				return onLeaveConfirmed();
			}
		} else if (target.id == gui.submitButtonId, exists currentTableClient = tableClient) {
			return currentTableClient.handleSubmitEvent();
		} else if (target.id == gui.undoButtonId, exists gameClient = tableClient?.gameClient) {
			return gameClient.handleUndoEvent();
		} else if (target.id == gui.exitButtonId) {
			if (exists currentTableClient = tableClient, currentTableClient.playerIsInMatch) {
				gui.showDialog("dialog-logout");
			} else {
				logout();
			}
			return true;
		}
		
		return false;
	}
	
	shared Boolean onChecker(HTMLElement checker) {

		if (exists gameClient = tableClient?.gameClient) {
			return gameClient.handleCheckerSelection(checker);
		} else {
			return false;
		}
	}
	
	shared Boolean onTimer() {

		if (exists currentClient = tableClient) {
			return currentClient.handleTimerEvent(now());
		} else {
			return false;
		}
	}
	
	shared Boolean onLeaveConfirmed() {

		if (exists currentTableClient = tableClient) {
			gui.hideLeaveButton();
			gameCommander(LeaveTableMessage(currentPlayerId, currentTableClient.tableId));
			return true;
		} else {
			return false;
		}
	}
	
	shared Boolean onLogoutConfirmed() {
		logout();
		return true;
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
	
	function handleTableMessage(OutboundTableMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			logout();
			return true;
		}
		
		// TODO cleanup this block
		if (is TableStateResponseMessage message) {
			if (message.isPlayerInQueue(currentPlayerId)) {
				gui.hideJoinButton();
				gui.showLeaveButton();
			} else {
				gui.hideLeaveButton();
				if (isPreview()) {
					gui.showJoinButton();
				}
			}
		} else if (is JoinedTableMessage message, message.playerId == currentPlayerId) {
			gui.hideJoinButton();
			gui.showLeaveButton();
		} else if (is LeftTableMessage message, message.playerId == currentPlayerId) {
			gui.hideLeaveButton();
			if (isPreview()) {
				gui.showJoinButton();
			}
		}
		
		if (is TableStateResponseMessage message, exists currentMatch = message.match) {
			if (currentMatch.hasPlayer(currentPlayerId) && isPreview()) {
				window.location.\iassign("/room/``message.tableId.roomId``/table/``message.tableId.table``/play");
			} else {
				// TODO some changes may occur on the state between the response and the registration
				gameEventClient = EventBusClient("OutboundGameMessage-``currentMatch.id``", onServerMessage, onServerError);
			}
		} else if (is CreatedMatchMessage message) {
			if (message.hasPlayer(currentPlayerId) && isPreview()) {
				window.location.\iassign("/room/``message.tableId.roomId``/table/``message.tableId.table``/play");
			} else {
				gameEventClient = EventBusClient("OutboundGameMessage-``message.matchId``", onServerMessage, onServerError);
			}
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleTableMessage(message);
		} else {
			return false;
		}
	}
	
	function handleMatchMessage(OutboundMatchMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (is MatchEndedMessage message) {
			gameEventClient?.close();
			if (!isPreview()) {
				tableEventClient?.close();
			}
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleMatchMessage(message);
		} else {
			return false;
		}
	}
	
	function handleGameMessage(OutboundGameMessage message) {
		
		if (is RoomResponseMessage message, !message.success) {
			return false;
		}
		
		if (exists currentClient = tableClient) {
			return currentClient.handleGameMessage(message);
		} else {
			return false;
		}
	}
	
	shared actual Boolean handleServerMessage(String typeName, Object json) {

		if (exists message = parseOutboundTableMessage(typeName, json)) {
			return handleTableMessage(message);
		} else if (exists message = parseOutboundMatchMessage(typeName, json)) {
			return handleMatchMessage(message);
		} else if (exists message = parseOutboundGameMessage(typeName, json)) {
			return handleGameMessage(message);
		} else {
			onServerError("Unsupported message type: ``typeName``");
			return true;
		}
	}

	void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
		print(formatRoomMessage(message));
		switch (message)
		case (is AcceptMatchMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/accept");
		}
		case (is StartGameMessage) {
			// ignore
		}
		case (is EndMatchMessage) {
			// ignore
		}
		case (is PlayerBeginMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/begin");
		}
		case (is MakeMoveMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/move/``message.sourcePosition``/``message.targetPosition``");
		}
		case (is UndoMovesMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/undomoves");
		}
		case (is EndTurnMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/endturn");
		}
		case (is EndGameMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/endgame");
		}
		case (is GameStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/state");
		}
		case (is JoinTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/join");
		}
		case (is LeaveTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/leave");
		}
		case (is TableStateRequestMessage) {
			value suffix = isPreview() then "currentstate" else "playerstate"; 
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/``suffix``");
		}
	}
	
	void login(PlayerInfo playerInfo, TableId tableId, Boolean viewTable) {
		print(playerInfo.toJson());
		tableClient = TableClient(currentPlayerId, tableId, gui, viewTable, gameCommander);
		tableEventClient = EventBusClient("OutboundTableMessage-``tableId``", onServerMessage, onServerError);
		gameCommander(TableStateRequestMessage(currentPlayerId, tableId, viewTable));
		gui.showBeginState(playerInfo);
	}
	
	shared void run() {
		if (exists tableId = extractTableId(), exists playerInfo = extractPlayerInfo()) {
			login(playerInfo, tableId, isPreview());
		} else {
			logout();
		}
	}
}