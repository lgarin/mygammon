import backgammon.client.browser {
	Event,
	window,
	newXMLHttpRequest
}
import backgammon.shared {
	systemPlayerId,
	PlayerId,
	InboundTableMessage,
	parseOutboundGameMessage,
	TableStateRequestMessage,
	UndoMovesMessage,
	EnterRoomMessage,
	LeaveTableMessage,
	FindEmptyTableMessage,
	EndMatchMessage,
	formatRoomMessage,
	InboundRoomMessage,
	StartGameMessage,
	EndGameMessage,
	AcceptMatchMessage,
	JoinTableMessage,
	PlayerStateRequestMessage,
	MakeMoveMessage,
	InboundGameMessage,
	parseOutboundTableMessage,
	FindMatchTableMessage,
	LeaveRoomMessage,
	EndTurnMessage,
	PlayerBeginMessage,
	parseOutboundMatchMessage,
	RoomStateRequestMessage,
	GameStateRequestMessage,
	InboundMatchMessage,
	parseOutboundRoomMessage,
	OutboundRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	OutboundGameMessage
}

import ceylon.json {
	Object,
	parse
}
import ceylon.regex {
	regex
}
import ceylon.time {
	now
}
abstract shared class BasePage() {
	
	variable PlayerId? playerId = null;
	
	shared formal Boolean handleRoomMessage(OutboundRoomMessage message);
	shared formal Boolean handleTableMessage(OutboundTableMessage message);
	shared formal Boolean handleMatchMessage(OutboundMatchMessage message);
	shared formal Boolean handleGameMessage(OutboundGameMessage message);
	
	function handleServerMessage(Object json)  {
		
		if (exists message = parseOutboundRoomMessage(json)) {
			return handleRoomMessage(message);
		} else if (exists message = parseOutboundTableMessage(json)) {
			return handleTableMessage(message);
		} else if (exists message = parseOutboundMatchMessage(json)) {
			return handleMatchMessage(message);
		} else if (exists message = parseOutboundGameMessage(json)) {
			return handleGameMessage(message);
		} else {
			return false;
		}
	}
	
	shared void onServerMessage(String messageString) {
		print(messageString);
		if (is Object json = parse(messageString)) {
			if (!handleServerMessage(json)) {
				onServerError("Cannot handle message: ``json.pretty``");
			}
		} else {
			onServerError("Cannot parse server response: ``messageString``");
		}
	}
	
	shared void onServerError(String messageString) {
		print(messageString);
		window.alert("An unexpected error occured.\r\nThe page will be reloaded.\r\n\r\nTimestamp:``now()``\r\nDetail:\r\n``messageString``");
		window.location.reload();
	}
	
	shared void makeApiRequest(String url) {
		value request = newXMLHttpRequest();
		request.open("GET", url, true);
		request.send();
		request.onload = void (Event event) {
			if (request.status == 200) {
				onServerMessage(request.responseText);
			} else if (request.status == 401) {
				window.location.\iassign("/start");
			} else {
				onServerError(request.statusText);
			}
		};
	}
	
	shared PlayerId? extractPlayerId() {
		if (!playerId exists) {
			value match = regex("playerId=([^\\;\\s]+)").find(window.document.cookie);
			if (exists match, exists id = match.groups[0]) {
				playerId = PlayerId(id);
			}
		}
		return playerId;
	}

	shared PlayerId currentPlayerId => extractPlayerId() else systemPlayerId;
	
	shared formal Boolean isBoardPreview();
	
	shared void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
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
			// ignore
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
			value suffix = isBoardPreview() then "currentstate" else "playerstate"; 
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/``suffix``");
		}
	}
	
	shared void roomCommander(InboundRoomMessage message) {
		switch(message)
		case (is RoomStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/listplayer");
		}
		case (is FindEmptyTableMessage) {
			makeApiRequest("/api/room/``message.roomId``/opentable");
		}
		case (is EnterRoomMessage) {}
		case (is LeaveRoomMessage) {
			makeApiRequest("/api/room/``message.roomId``/leave");
		}
		case (is PlayerStateRequestMessage) {
			makeApiRequest("/api/room/``message.roomId``/player/``message.playerId``/state");
		}
		case (is FindMatchTableMessage) {}
	}
	
}