import backgammon.common {
	RoomId,
	GameStateResponseMessage,
	TableStateRequestMessage,
	GameStateRequestMessage,
	formatRoomMessage,
	TableStateResponseMessage,
	AcceptedMatchMessage,
	AcceptMatchMessage,
	LeaveTableMessage,
	LeftTableMessage
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

	void handleTableStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			eventBus.sendInboundRoomMessage(TableStateRequestMessage(playerId, RoomId(tableId.roomId), tableId.table), void (Throwable|TableStateResponseMessage result) {
				if (is Throwable result) {
					context.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleTableLeaveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			eventBus.sendInboundTableMessage(LeaveTableMessage(playerId, tableId), void (Throwable|LeftTableMessage result) {
				if (is Throwable result) {
					context.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleGameStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			eventBus.sendInboundGameMessage(GameStateRequestMessage(matchId, playerId), void (Throwable|GameStateResponseMessage result) {
				if (is Throwable result) {
					context.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handlMatchAcceptRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			eventBus.sendInboundMatchMessage(AcceptMatchMessage(playerId, matchId), void (Throwable|AcceptedMatchMessage result) {
				if (is Throwable result) {
					context.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}

	shared Router createRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/leave").handler(handleTableLeaveRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/accept").handler(handlMatchAcceptRequest);
		return restApi;
	}
}