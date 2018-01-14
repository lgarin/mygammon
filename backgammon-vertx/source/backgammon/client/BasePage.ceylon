import backgammon.client.browser {
	window,
	document,
	newXMLHttpRequest,
	Event
}
import backgammon.shared {
	systemPlayerId,
	PlayerId,
	InboundTableMessage,
	TableStateRequestMessage,
	UndoMovesMessage,
	EnterRoomMessage,
	LeaveTableMessage,
	FindEmptyTableMessage,
	EndMatchMessage,
	InboundRoomMessage,
	StartGameMessage,
	EndGameMessage,
	AcceptMatchMessage,
	JoinTableMessage,
	PlayerStateRequestMessage,
	MakeMoveMessage,
	InboundGameMessage,
	FindMatchTableMessage,
	LeaveRoomMessage,
	EndTurnMessage,
	PlayerBeginMessage,
	RoomStateRequestMessage,
	GameStateRequestMessage,
	InboundMatchMessage,
	OutboundRoomMessage,
	OutboundTableMessage,
	OutboundMatchMessage,
	OutboundGameMessage,
	TakeTurnMessage,
	PingMatchMessage,
	applicationMessages,
	OutboundPlayerRosterMessage,
	InboundPlayerRosterMessage,
	PlayerLoginMessage,
	PlayerStatisticUpdateMessage,
	PlayerDetailRequestMessage
}

import ceylon.json {
	Object,
	parse
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
	shared formal Boolean handleRosterMessage(OutboundPlayerRosterMessage message);
	
	function handleServerMessage(Object json)  {
		
		if (exists message = applicationMessages.parse<OutboundRoomMessage>(json)) {
			return handleRoomMessage(message);
		} else if (exists message = applicationMessages.parse<OutboundTableMessage>(json)) {
			return handleTableMessage(message);
		} else if (exists message = applicationMessages.parse<OutboundMatchMessage>(json)) {
			return handleMatchMessage(message);
		} else if (exists message = applicationMessages.parse<OutboundGameMessage>(json)) {
			return handleGameMessage(message);
		} else if (exists message = applicationMessages.parse<OutboundPlayerRosterMessage>(json)) {
			return handleRosterMessage(message);
		} else {
			return false;
		}
	}
	
	shared String? splitString(String input, String lowerDelimiter, String? upperDelimiter = null) {
		value lowerPosition = input.firstInclusion(lowerDelimiter);
		if (exists lowerPosition) {
			value upperPosition =  if (exists upperDelimiter) then input.firstInclusion(upperDelimiter, lowerPosition + lowerDelimiter.size) else input.size;
			if (exists upperPosition) {
				return input.substring(lowerPosition + lowerDelimiter.size, upperPosition);
			}
		}
		return null;
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
		request.onload = void (Event event) {
			if (request.status == 200) {
				onServerMessage(request.responseText);
			} else if (request.status == 401) {
				window.location.\iassign("/start");
			} else {
				onServerError(request.statusText);
			}
		};
		request.send();
	}
	
	shared PlayerId? extractPlayerId() {
		if (!playerId exists) {
			if (exists id = splitString(document.cookie, "playerId=", "; ")) {
				playerId = PlayerId(id);
			} else if (exists id = splitString(document.cookie, "playerId=")) {
				playerId = PlayerId(id);
			}
		}
		return playerId;
	}

	shared PlayerId currentPlayerId => extractPlayerId() else systemPlayerId;
	
	shared formal Boolean isBoardPreview();
	
	shared void gameCommander(InboundGameMessage|InboundMatchMessage|InboundTableMessage message) {
		print(applicationMessages.format(message));
		switch (message)
		case (is AcceptMatchMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/accept");
		}
		case (is StartGameMessage) {
			// ignore
		}
		case (is PingMatchMessage) {
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
		case (is TakeTurnMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/taketurn");
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
	
	shared void rosterCommander(InboundPlayerRosterMessage message) {
		switch (message)
		case (is PlayerStatisticUpdateMessage) {
			// ignore
		}
		case (is PlayerLoginMessage) {
			// ignore
		}
		case (is PlayerDetailRequestMessage) {
			makeApiRequest("/api/roster/playerdetail");
		}
	}
}