import backgammon.common {
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
	MakeMoveMessage
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
	
	void handlEndGameRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, EndGameMessage(matchId, playerId));
		}
	}

	shared Router createRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/leave").handler(handleTableLeaveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/accept").handler(handlMatchAcceptRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/begin").handler(handlPlayerBeginRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/move/:sourcePosition/:targetPosition").handler(handlMakeMoveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/undomoves").handler(handlUndoMovesRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/endturn").handler(handlEndTurnRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/endgame").handler(handlEndGameRequest);
		return restApi;
	}
}