import backgammon.common {
	RoomId,
	TableStateRequestMessage,
	GameStateRequestMessage,
	formatRoomMessage,
	AcceptMatchMessage,
	LeaveTableMessage,
	InboundGameMessage,
	InboundMatchMessage,
	InboundRoomMessage,
	InboundTableMessage,
	RoomMessage
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
			forwardResponse(context, TableStateRequestMessage(playerId, RoomId(tableId.roomId), tableId.table));
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleTableLeaveRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists tableId = context.getRequestTableId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, LeaveTableMessage(playerId, tableId));
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleGameStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, GameStateRequestMessage(matchId, playerId));
		} else {
			context.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handlMatchAcceptRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, AcceptMatchMessage(playerId, matchId));
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