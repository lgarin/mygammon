import backgammon.server {
	GameRoomRoutingContext
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
	PlayerStatistic,
	PlayerStatisticOutputMessage,
	PlayerLoginMessage
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext,
	Router
}
import backgammon.server.remote {

	KeycloakAuthClient,
	KeycloakUserInfo
}
import backgammon.server.bus {

	GameRoomEventBus,
	PlayerRosterEventBus
}

final class GameRoomRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value roomEventBus = GameRoomEventBus(vertx);
	value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);
	value authClient = KeycloakAuthClient(vertx, serverConfig.keycloakLoginUrl);
	
	void enterRoom(RoutingContext routingContext, PlayerInfo playerInfo, PlayerStatistic playerStat) {
		value context = GameRoomRoutingContext(routingContext);
		roomEventBus.sendInboundMessage(EnterRoomMessage(playerInfo.playerId, RoomId(serverConfig.roomId), playerInfo, playerStat), void (Throwable|RoomActionResponseMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				context.sendRedirect("/room/``serverConfig.roomId``");
			}
		});
	}
	
	void completeLogin(RoutingContext routingContext, PlayerInfo playerInfo) {
		value context = GameRoomRoutingContext(routingContext);
		context.setCurrentPlayerInfo(playerInfo);
		repoEventBus.sendInboundMessage(PlayerLoginMessage(playerInfo), void (Throwable|PlayerStatisticOutputMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				value playerLevel = result.statistic.computeLevel(serverConfig.scoreLevels);
				enterRoom(routingContext, playerInfo.withLevel(playerLevel), result.statistic);
			}
		});
	}
	
	void fetchUserInfo(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		void handler(KeycloakUserInfo|Throwable result) {
			if (is KeycloakUserInfo result) {
				value playerInfo = PlayerInfo(result.userId, result.displayName);
				completeLogin(routingContext, playerInfo);
			} else {
				context.clearUser();
				context.fail(result);
			}
		}
		authClient.fetchUserInfo(routingContext, handler);
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
			roomEventBus.sendInboundMessage(FindMatchTableMessage(playerId, roomId), void (Throwable|FoundMatchTableMessage result) {
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
		routingContext.reroute("static/board.html");
	}
	
	void handleLogout(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		if (exists playerInfo = context.getCurrentPlayerId(false)) {
			roomEventBus.sendInboundMessage(LeaveRoomMessage(PlayerId(playerInfo.id), RoomId(serverConfig.roomId)), void (Anything response) {
				authClient.logout(routingContext, void (Throwable? error) {
					if (exists error) {
						context.fail(error);
					} else {
						context.clearUser();
						context.sendRedirect(serverConfig.homeUrl);
					}
				});
			});
		} else {
			context.sendRedirect(serverConfig.homeUrl);
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