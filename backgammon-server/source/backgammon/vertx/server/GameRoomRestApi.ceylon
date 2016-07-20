import backgammon.common {
	RoomId,
	GameStateResponseMessage,
	TableStateRequestMessage,
	GameStateRequestMessage,
	formatRoomMessage,
	TableStateResponseMessage
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
					rc.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			rc.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleGameStateRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists matchId = context.getRequestMatchId(), exists playerId = context.getCurrentPlayerId()) {
			eventBus.sendInboundGameMessage(GameStateRequestMessage(matchId, playerId), void (Throwable|GameStateResponseMessage result) {
				if (is Throwable result) {
					rc.fail(result);
				} else {
					context.writeJsonResponse(formatRoomMessage(result));
				}
			});
		} else {
			rc.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}

	shared Router createRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
		return restApi;
	}
}