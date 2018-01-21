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
import java.net {

	URLEncoder
}

final class GameRoomRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value roomEventBus = GameRoomEventBus(vertx, serverConfig);
	value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);
	value authClient = KeycloakAuthClient(vertx, serverConfig.keycloakLoginUrl);
	value restApi = GameRoomRestApi(vertx, roomEventBus);
	value encodedStartUrl = URLEncoder.encode("http://``serverConfig.hostname``:``serverConfig.port``/start");
	
	void enterRoom(RoutingContext routingContext, PlayerInfo playerInfo, PlayerStatistic playerStat) {
		value context = GameRoomRoutingContext(routingContext);
		roomEventBus.sendInboundMessage(EnterRoomMessage(playerInfo.playerId, RoomId(serverConfig.roomId), playerInfo, playerStat), void (Throwable|RoomActionResponseMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.sendRedirect("/room/``serverConfig.roomId``");
			}
		});
	}
	
	void completeLogin(RoutingContext routingContext, PlayerInfo playerInfo) {
		value context = GameRoomRoutingContext(routingContext);
		repoEventBus.sendInboundMessage(PlayerLoginMessage(playerInfo), void (Throwable|PlayerStatisticOutputMessage result) {
			if (is Throwable result) {
				context.clearUser();
				context.fail(result);
			} else {
				context.setCurrentPlayerInfo(result.playerInfo);
				enterRoom(routingContext, result.playerInfo, result.statistic);
			}
		});
	}
	
	void fetchUserInfo(RoutingContext routingContext) {
		value context = GameRoomRoutingContext(routingContext);
		void handler(KeycloakUserInfo|Throwable result) {
			if (is KeycloakUserInfo result) {
				completeLogin(routingContext, PlayerInfo(result.userId, result.displayName));
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
					context.fail(result);
				} else if (exists table = result.table) {
					context.sendRedirect("/room/``roomId``/table/``table``/play");
				} else {
					context.failWithServiceUnavailable();
				}
			});
		} else {
			context.sendRedirect("/start");
		}
	}
	
	void handleAccount(RoutingContext routingContext) {
		routingContext.reroute("static/account.html");
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
						context.sendRedirect("``serverConfig.keycloakLogoutUrl``?redirect_uri=``encodedStartUrl``");
					}
				});
			});
		} else {
			context.sendRedirect("``serverConfig.keycloakLogoutUrl``?redirect_uri=``encodedStartUrl``");
		}
	}

	shared Router createRootRouter() {
		value router = routerFactory.router(vertx);
		router.route("/").handler(handleStart);
		router.route("/start").handler(handleStart);
		router.route("/logout").handler(handleLogout);
		router.route("/room/:roomId").handler(handleRoom);
		router.route("/room/:roomId/play").handler(handlePlay);
		router.route("/room/:roomId/account").handler(handleAccount);
		router.route("/room/:roomId/table/:tableId/view").handler(handleTable);
		router.route("/room/:roomId/table/:tableId/play").handler(handleTable);
		return router;
	}
	
	shared Router createApiRouter() => restApi.createRouter();
	
	shared Router createEventBusRouter() => roomEventBus.createEventBusRouter();
}