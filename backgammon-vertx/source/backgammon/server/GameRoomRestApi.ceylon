import backgammon.shared {
	TableStateRequestMessage,
	GameStateRequestMessage,
	formatRoomMessage,
	AcceptMatchMessage,
	LeaveTableMessage,
	InboundGameMessage,
	InboundMatchMessage,
	InboundRoomMessage,
	InboundTableMessage,
	RoomMessage,
	PlayerBeginMessage,
	EndTurnMessage,
	EndGameMessage,
	UndoMovesMessage,
	MakeMoveMessage,
	RoomStateRequestMessage,
	FindEmptyTableMessage,
	JoinTableMessage,
	LeaveRoomMessage,
	PlayerStateRequestMessage
}
import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	Router,
	RoutingContext
}

final class GameRoomRestApi(Vertx vertx) {
	
	value eventBus = GameRoomEventBus(vertx);

	void forwardResponse(GameRoomRoutingContext context, InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message) {
		eventBus.sendInboundMessage(message, void (Throwable|RoomMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.writeJsonResponse(formatRoomMessage(result));
			}
		});
	}

	void handleTableStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, TableStateRequestMessage(playerId, tableId));
		}
	}
	
	void handleTableLeaveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, LeaveTableMessage(playerId, tableId));
		}
	}
	
	void handleTableJoinRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, JoinTableMessage(playerId, tableId));
		}
	}
	
	void handleGameStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, GameStateRequestMessage(matchId, playerId));
		}
	}
	
	void handlMatchAcceptRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, AcceptMatchMessage(playerId, matchId));
		}
	}
	
	void handlPlayerBeginRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, PlayerBeginMessage(matchId, playerId));
		}
	}
	
	void handlMakeMoveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId(), exists sourcePosition = context.getRequestSourcePosition(), exists targetPosition = context.getRequestTargetPosition()) {
			forwardResponse(context, MakeMoveMessage(matchId, playerId, sourcePosition, targetPosition));
		}
	}
	
	void handlUndoMovesRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, UndoMovesMessage(matchId, playerId));
		}
	}

	void handlEndTurnRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, EndTurnMessage(matchId, playerId));
		}
	}
	
	// TODO not used
	void handlEndGameRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, EndGameMessage(matchId, playerId));
		}
	}
	
	void handlePlayerListRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, RoomStateRequestMessage(playerId, roomId));
		}
	}
	
	void handleOpenTableRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, FindEmptyTableMessage(playerId, roomId));
		}
	}
	
	void handleRoomLeaveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, LeaveRoomMessage(playerId, roomId));
		}
	}
	
	void handlePlayerStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getRequestPlayerId()) {
			forwardResponse(context, PlayerStateRequestMessage(playerId, roomId));
		}
	}

	shared Router createRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/listplayer").handler(handlePlayerListRequest);
		restApi.get("/room/:roomId/opentable").handler(handleOpenTableRequest);
		restApi.get("/room/:roomId/leave").handler(handleRoomLeaveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/leave").handler(handleTableLeaveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/join").handler(handleTableJoinRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/accept").handler(handlMatchAcceptRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/begin").handler(handlPlayerBeginRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/move/:sourcePosition/:targetPosition").handler(handlMakeMoveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/undomoves").handler(handlUndoMovesRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/endturn").handler(handlEndTurnRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/endgame").handler(handlEndGameRequest);
		restApi.get("/room/:roomId/player/:playerId/state").handler(handlePlayerStateRequest);
		return restApi;
	}
}