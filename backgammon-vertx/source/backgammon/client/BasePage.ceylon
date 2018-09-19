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
	PlayerDetailRequestMessage,
	PlayerStatisticRequestMessage,
	OutboundScoreBoardMessage,
	InboundScoreBoardMessage,
	QueryGameStatisticMessage,
	GameStatisticMessage,
	ControlRollMessage,
	ApplicationMessage,
	OutboundChatRoomMessage,
	InboundChatRoomMessage,
	PostChatMessage,
	ChatHistoryRequestMessage,
	PlayerInfoRequestMessage,
	ChatMissedRequestMessage,
	UndoTurnMessage,
	ReplayTurnMessage
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
	shared formal Boolean handleScoreMessage(OutboundScoreBoardMessage message);
	shared formal Boolean handleChatMessage(OutboundChatRoomMessage message);
	
	function handleServerMessage(Object json)  {
		value message = applicationMessages.parse<ApplicationMessage>(json);
		if (is OutboundRoomMessage message) {
			return handleRoomMessage(message);
		} else if (is OutboundTableMessage message) {
			return handleTableMessage(message);
		} else if (is OutboundMatchMessage message) {
			return handleMatchMessage(message);
		} else if (is OutboundGameMessage message) {
			return handleGameMessage(message);
		} else if (is OutboundPlayerRosterMessage message) {
			return handleRosterMessage(message);
		} else if (is OutboundScoreBoardMessage message) {
			return handleScoreMessage(message);
		} else if (is OutboundChatRoomMessage message) {
			return handleChatMessage(message);
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
	
	
	shared void onServerError(String messageString) {
		print(messageString);
		window.alert("An unexpected error occured.\r\nThe page will be reloaded.\r\n\r\nTimestamp:``now()``\r\nDetail:\r\n``messageString``");
		window.location.reload();
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
	
	shared void makeApiRequest(String url, String? data = null) {
		value request = newXMLHttpRequest();
		request.open(data exists then "POST" else "GET", url, true);
		request.onload = void (Event event) {
			if (request.status == 200) {
				onServerMessage(request.responseText);
			} else if (request.status == 401) {
				window.location.reload();
			} else {
				onServerError(request.statusText);
			}
		};
		request.send(data);
	}
	
	shared PlayerId? extractPlayerId() {
		if (!playerId exists, exists cookie = extractCookie("playerId")) {
			playerId = PlayerId(cookie);
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
		case (is ControlRollMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/controlroll/``message.roll.firstValue``/``message.roll.secondValue``");
		}
		case (is UndoTurnMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/undoturn");
		}
		case (is ReplayTurnMessage) {
			makeApiRequest("/api/room/``message.roomId``/table/``message.tableId.table``/match/``message.matchId.timestamp.millisecondsOfEpoch``/replayturn");
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
			assert (false);
		}
		case (is PlayerLoginMessage) {
			assert (false);
		}
		case (is PlayerInfoRequestMessage) {
			assert (false);
		}
		case (is PlayerDetailRequestMessage) {
			makeApiRequest("/api/roster/playerdetail");
		}
		case (is PlayerStatisticRequestMessage) {
			makeApiRequest("/api/roster/playerstatistic");
		}
	}
	
	shared void scoreCommander(InboundScoreBoardMessage message) {
		switch (message)
		case (is GameStatisticMessage) {
			// ignore
		}
		case (is QueryGameStatisticMessage) {
			makeApiRequest("/api/score/playerdetail/``message.playerId``");
		}
	}
	
	shared void chatCommander(InboundChatRoomMessage message) {
		switch (message)
		case (is PostChatMessage) {
			makeApiRequest("/api/chat/``message.roomId``/post", message.message);
		}
		case (is ChatHistoryRequestMessage) {
			makeApiRequest("/api/chat/``message.roomId``/history");
		}
		case (is ChatMissedRequestMessage) {
			makeApiRequest("/api/chat/``message.roomId``/new/``message.lastMessageId``");
		}
	}
	
	
	shared String? extractCookie(String name) {
		if (exists result = splitString(document.cookie, "``name``=", "; ")) {
			return result;
		} else if (exists result = splitString(document.cookie, "``name``=")) {
			return result;
		} else {
			return null;
		}
	}
	
	shared void writeCookie(String name, String val, String path) {
		document.cookie = "``name``=``val``; path=``path``";
	}
}