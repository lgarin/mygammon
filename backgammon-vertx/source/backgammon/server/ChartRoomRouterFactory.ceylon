import backgammon.shared {

	InboundChatRoomMessage,
	applicationMessages,
	OutboundChatRoomMessage,
	PostChatMessage,
	ChatHistoryRequestMessage
}
import backgammon.server.bus {

	ChatRoomEventBus
}
import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.web {

	RoutingContext,
	routerFactory=router,
	Router
}

final class ChartRoomRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value eventBus = ChatRoomEventBus(vertx, serverConfig);

	void forwardResponse(GameRoomRoutingContext context, InboundChatRoomMessage message) {
		eventBus.sendInboundMessage(message, void (Throwable|OutboundChatRoomMessage result) {
			if (is Throwable result) {
				context.fail(result);
			} else {
				context.writeJsonResponse(applicationMessages.format(result));
			}
		});
	}
	
	void handleChatPostRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, PostChatMessage(playerId, roomId, rc.getBodyAsString("UTF-8") else ""));
		}
	}
	
	void handleChatHistoryRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, ChatHistoryRequestMessage(playerId, roomId));
		}
	}
	
	shared Router createApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.post("/:roomId/chat/post").handler(handleChatPostRequest);
		restApi.get("/:roomId/chat/history").handler(handleChatHistoryRequest);
		return restApi;
	}
}