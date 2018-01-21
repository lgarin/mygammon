import backgammon.server.bus {
	ScoreBoardEventBus
}
import backgammon.shared {
	applicationMessages,
	InboundScoreBoardMessage,
	OutboundScoreBoardMessage,
	QueryGameStatisticMessage
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	RoutingContext,
	routerFactory=router,
	Router
}
final class ScoreBoardRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value eventBus = ScoreBoardEventBus(vertx, serverConfig);

	void forwardResponse(GameRoomRoutingContext context, InboundScoreBoardMessage message) {
		eventBus.sendInboundMessage(message, void (Throwable|OutboundScoreBoardMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.writeJsonResponse(applicationMessages.format(result));
			}
		});
	}

	void handlePlayerDetailRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		
		if (exists playerId = context.getRequestPlayerId()) {
			forwardResponse(context, QueryGameStatisticMessage(playerId));
		}
	}
	
	shared Router createApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/playerdetail/:playerId").handler(handlePlayerDetailRequest);
		return restApi;
	}
}