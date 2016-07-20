import backgammon.common {
	PlayerInfo,
	TableId,
	RoomId,
	GameStateResponseMessage,
	TableStateRequestMessage,
	GameStateRequestMessage,
	MatchId,
	formatRoomMessage,
	TableStateResponseMessage,
	PlayerId
}

import ceylon.json {
	Object
}
import ceylon.time {
	Instant
}

import io.vertx.ceylon.web {
	Router,
	RoutingContext,
	routerFactory=router
}
import io.vertx.ceylon.core {

	Vertx
}
class GameRoomRestApi(GameRoomClient gameRoomClient) extends HttpGameRoom() {
	
	void writeJsonResponse(RoutingContext rc, Object json) {
		value response = json.string;
		rc.response().headers().add("Content-Length", response.size.string);
		rc.response().headers().add("Content-Type", "application/json");
		rc.response().write(response).end();
	}
	
	void handleTableStateRequest(RoutingContext rc) {
		if (exists tableId = getRequestTableId(rc), exists playerId = getCurrentPlayerId(rc)) {
			gameRoomClient.sendInboundRoomMessage(TableStateRequestMessage(playerId, RoomId(tableId.roomId), tableId.table), void (Throwable|TableStateResponseMessage result) {
				if (is Throwable result) {
					rc.fail(result);
				} else {
					writeJsonResponse(rc, formatRoomMessage(result));
				}
			});
		} else {
			rc.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}
	
	void handleGameStateRequest(RoutingContext rc) {
		if (exists matchId = getRequestMatchId(rc), exists playerId = getCurrentPlayerId(rc)) {
			gameRoomClient.sendInboundGameMessage(GameStateRequestMessage(matchId, playerId), void (Throwable|GameStateResponseMessage result) {
				if (is Throwable result) {
					rc.fail(result);
				} else {
					writeJsonResponse(rc, formatRoomMessage(result));
				}
			});
		} else {
			rc.fail(Exception("Invalid request: ``rc.request().uri()``"));
		}
	}

	shared void defineRoutes(Router restApi) {
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		restApi.get("/room/:roomId/table/:tableIndex/match/:matchTimestamp/state").handler(handleGameStateRequest);
	}
}