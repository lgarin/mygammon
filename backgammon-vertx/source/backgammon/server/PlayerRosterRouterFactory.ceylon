import backgammon.server.bus {

	PlayerRosterEventBus
}
import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.web {

	routerFactory=router,
	Router,
	RoutingContext
}
import backgammon.shared {

	applicationMessages,
	InboundPlayerRosterMessage,
	OutboundPlayerRosterMessage,
	PlayerDetailRequestMessage,
	PlayerStatisticRequestMessage
}

final class PlayerRosterRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value eventBus = PlayerRosterEventBus(vertx, serverConfig);

	void forwardResponse(GameRoomRoutingContext context, InboundPlayerRosterMessage message) {
		eventBus.sendInboundMessage(message, void (Throwable|OutboundPlayerRosterMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.writeJsonResponse(applicationMessages.format(result));
			}
		});
	}

	void handlePlayerDetailRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		
		if (exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, PlayerDetailRequestMessage(playerId));
		}
	}
	
	void handlePlayerStatisticRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		
		if (exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, PlayerStatisticRequestMessage(playerId));
		}
	}
	
	shared Router createApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/playerdetail").handler(handlePlayerDetailRequest);
		restApi.get("/playerstatistic").handler(handlePlayerStatisticRequest);
		return restApi;
	}
}