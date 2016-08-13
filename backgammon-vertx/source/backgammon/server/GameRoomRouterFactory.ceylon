import backgammon.shared {
	FindMatchTableMessage,
	PlayerInfo,
	RoomId,
	PlayerId,
	EnterRoomMessage,
	EnteredRoomMessage,
	FoundMatchTableMessage
}
import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext,
	Router
}
import backgammon.server {
	GameRoomRoutingContext,
	GameRoomEventBus,
	GoogleUserInfo,
	GoogleProfileClient
}

final class GameRoomRouterFactory(Vertx vertx, String roomId) {
	
	value eventBus = GameRoomEventBus(vertx);
	value googleProfileClient = GoogleProfileClient(vertx);
	
	void completeLogin(RoutingContext routingContext, PlayerInfo playerInfo) {
		value context = GameRoomRoutingContext(routingContext);
		context.setCurrentPlayerInfo(playerInfo);
		eventBus.sendInboundMessage(EnterRoomMessage(PlayerId(playerInfo.id), RoomId(roomId), playerInfo), void (Throwable|EnteredRoomMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				context.sendRedirect("/room/``roomId``/play");
			}
		});
	}
	
	void handleStart(RoutingContext routingContext) {

		void handler(GoogleUserInfo? userInfo) {
			if (exists userInfo) {
				value playerInfo = PlayerInfo(userInfo.userId, userInfo.displayName, userInfo.pictureUrl);
				completeLogin(routingContext, playerInfo);
			} else {
				routingContext.clearUser();
				routingContext.fail(Exception("No info returned for current user"));
			}
		}
		
		googleProfileClient.fetchUserInfo(routingContext, handler);
	}

	void handlePlay(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerId = context.getCurrentPlayerId(false), exists roomId = context.getRequestRoomId(false)) {
			eventBus.sendInboundMessage(FindMatchTableMessage(playerId, roomId), void (Throwable|FoundMatchTableMessage result) {
				if (is Throwable result) {
					routingContext.fail(result);
				} else if (exists table = result.table) {
					context.sendRedirect("/room/``roomId``/table/``table``");
				} else {
					routingContext.fail(503);
				}
			});
		} else {
			context.sendRedirect("/start");
		}
	}
	
	void handleTable(RoutingContext routingContext) {
		// TODO magic value
		routingContext.reroute("static/board.html");
	}

	shared Router createRouter() {
		value router = routerFactory.router(vertx);
		router.route("/start").handler(handleStart);
		router.route("/room/:roomId/play").handler(handlePlay);
		router.route("/room/:roomId/table/:tableId").handler(handleTable);
		return router;
	}
}