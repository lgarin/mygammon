import backgammon.server {
	GameRoomRoutingContext,
	GameRoomEventBus,
	GoogleUserInfo,
	GoogleProfileClient
}
import backgammon.shared {
	FindMatchTableMessage,
	PlayerInfo,
	RoomId,
	PlayerId,
	EnterRoomMessage,
	FoundMatchTableMessage,
	LeaveRoomMessage,
	RoomActionResponseMessage,
	PlayerStateRequestMessage,
	PlayerStateMessage
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext,
	Router
}

final class GameRoomRouterFactory(Vertx vertx, String roomId, Integer initialPlayerBalance) {
	
	value eventBus = GameRoomEventBus(vertx);
	value googleProfileClient = GoogleProfileClient(vertx);
	
	void completeLogin(RoutingContext routingContext, PlayerInfo playerInfo) {
		value context = GameRoomRoutingContext(routingContext);
		context.setCurrentPlayerInfo(playerInfo);
		eventBus.sendInboundMessage(EnterRoomMessage(PlayerId(playerInfo.id), RoomId(roomId), playerInfo), void (Throwable|RoomActionResponseMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				context.sendRedirect("/room/``roomId``");
			}
		});
	}
	
	void fetchUserInfo(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		void handler(GoogleUserInfo? userInfo) {
			if (exists userInfo) {
				value playerInfo = PlayerInfo(userInfo.userId, userInfo.displayName, initialPlayerBalance, userInfo.pictureUrl, userInfo.iconUrl);
				completeLogin(routingContext, playerInfo);
			} else {
				context.clearUser();
				context.fail(Exception("No info returned for current user"));
			}
		}
		googleProfileClient.fetchUserInfo(routingContext, handler);
	}
	
	void handleStart(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerInfo = context.getCurrentPlayerInfo()) {
			completeLogin(routingContext, playerInfo);
		} else {
			fetchUserInfo(routingContext);
		}
	}
	
	void handleRoom(RoutingContext routingContext) {
		routingContext.reroute("static/room.html");
	}

	void handlePlay(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerId = context.getCurrentPlayerId(false), exists roomId = context.getRequestRoomId(false)) {
			eventBus.sendInboundMessage(FindMatchTableMessage(playerId, roomId), void (Throwable|FoundMatchTableMessage result) {
				if (is Throwable result) {
					routingContext.fail(result);
				} else if (exists table = result.table) {
					context.sendRedirect("/room/``roomId``/table/``table``/play");
				} else {
					routingContext.fail(503);
				}
			});
		} else {
			context.sendRedirect("/start");
		}
	}
	
	void handleTable(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerId = context.getCurrentPlayerId(false), exists roomId = context.getRequestRoomId(false)) {
			eventBus.sendInboundMessage(PlayerStateRequestMessage(playerId, roomId), void (Throwable|PlayerStateMessage result) {
				if (is Throwable result) {
					routingContext.fail(result);
				} else if (exists state = result.state) {
					context.setCurrentPlayerInfo(state.toPlayerInfo());
					routingContext.reroute("static/board.html");
				} else {
					routingContext.fail(503);
				}
			});
		} else {
			context.failWithUnauthorized();
		}
	}
	
	void handleLogout(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerInfo = context.getCurrentPlayerId(false)) {
			eventBus.sendInboundMessage(LeaveRoomMessage(PlayerId(playerInfo.id), RoomId(roomId)), void (Anything response) {
				googleProfileClient.logout(routingContext, void (Boolean success) {
					if (success) {
						context.clearUser();
						context.sendRedirect("/start");
					}
				});
			});
		}
	}

	shared Router createRouter() {
		value router = routerFactory.router(vertx);
		router.route("/start").handler(handleStart);
		router.route("/logout").handler(handleLogout);
		router.route("/room/:roomId").handler(handleRoom);
		router.route("/room/:roomId/play").handler(handlePlay);
		router.route("/room/:roomId/table/:tableId/view").handler(handleTable);
		router.route("/room/:roomId/table/:tableId/play").handler(handleTable);
		return router;
	}
}