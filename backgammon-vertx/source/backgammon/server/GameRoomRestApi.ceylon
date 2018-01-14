import backgammon.shared {
	TableStateRequestMessage,
	GameStateRequestMessage,
	AcceptMatchMessage,
	LeaveTableMessage,
	InboundGameMessage,
	InboundMatchMessage,
	InboundRoomMessage,
	InboundTableMessage,
	RoomMessage,
	PlayerBeginMessage,
	EndTurnMessage,
	UndoMovesMessage,
	MakeMoveMessage,
	RoomStateRequestMessage,
	FindEmptyTableMessage,
	JoinTableMessage,
	LeaveRoomMessage,
	PlayerStateRequestMessage,
	TakeTurnMessage,
	applicationMessages
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	Router,
	RoutingContext
}
import backgammon.server.bus {

	GameRoomEventBus
}

final class GameRoomRestApi(Vertx vertx, GameRoomEventBus eventBus) {
	
	void forwardResponse(GameRoomRoutingContext context, InboundRoomMessage|InboundTableMessage|InboundMatchMessage|InboundGameMessage message) {
		eventBus.sendInboundMessage(message, void (Throwable|RoomMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.writeJsonResponse(applicationMessages.format(result));
			}
		});
	}

	void handleTableStateRequest(Boolean current)(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, TableStateRequestMessage(playerId, tableId, current));
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
	
	void handleMatchAcceptRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, AcceptMatchMessage(playerId, matchId));
		}
	}
	
	void handlePlayerBeginRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, PlayerBeginMessage(matchId, playerId));
		}
	}
	
	void handleMakeMoveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId(), exists sourcePosition = context.getRequestSourcePosition(), exists targetPosition = context.getRequestTargetPosition()) {
			forwardResponse(context, MakeMoveMessage(matchId, playerId, sourcePosition, targetPosition));
		}
	}
	
	void handleUndoMovesRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, UndoMovesMessage(matchId, playerId));
		}
	}

	void handleEndTurnRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, EndTurnMessage(matchId, playerId));
		}
	}
	
	void handleTakeTurnRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, TakeTurnMessage(matchId, playerId));
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
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getRequestPlayerId(), context.getCurrentPlayerId() exists) {
			forwardResponse(context, PlayerStateRequestMessage(playerId, roomId));
		}
	}

	shared Router createRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/:roomId/listplayer").handler(handlePlayerListRequest);
		restApi.get("/:roomId/opentable").handler(handleOpenTableRequest);
		restApi.get("/:roomId/leave").handler(handleRoomLeaveRequest);
		restApi.get("/:roomId/table/:tableIndex/currentstate").handler(handleTableStateRequest(true));
		restApi.get("/:roomId/table/:tableIndex/playerstate").handler(handleTableStateRequest(false));
		restApi.get("/:roomId/table/:tableIndex/leave").handler(handleTableLeaveRequest);
		restApi.get("/:roomId/table/:tableIndex/join").handler(handleTableJoinRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/accept").handler(handleMatchAcceptRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/begin").handler(handlePlayerBeginRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/move/:sourcePosition/:targetPosition").handler(handleMakeMoveRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/undomoves").handler(handleUndoMovesRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/endturn").handler(handleEndTurnRequest);
		restApi.get("/:roomId/table/:tableIndex/match/:matchTimestamp/taketurn").handler(handleTakeTurnRequest);
		restApi.get("/:roomId/player/:playerId/state").handler(handlePlayerStateRequest);
		return restApi;
	}
}