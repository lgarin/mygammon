import backgammon.shared {

	InboundChatRoomMessage,
	applicationMessages,
	OutboundChatRoomMessage,
	PostChatMessage,
	ChatHistoryRequestMessage,
	ChatMissedRequestMessage
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
import io.vertx.ceylon.core.buffer {

	Buffer
}

final class ChatRoomRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
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
			rc.request().bodyHandler((Buffer body) {
				forwardResponse(context, PostChatMessage(playerId, roomId, body.toString("UTF-8")));
			});
		}
	}
	
	void handleChatHistoryRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId()) {
			forwardResponse(context, ChatHistoryRequestMessage(playerId, roomId));
		}
	}
	
	void handleChatMissedRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
		if (exists roomId = context.getRequestRoomId(), exists playerId = context.getCurrentPlayerId(), exists lastMessageId = context.getRequestIntegerParameter("lastMessageId")) {
			forwardResponse(context, ChatMissedRequestMessage(playerId, roomId, lastMessageId));
		}
	}
	
	shared Router createApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.post("/:roomId/post").handler(handleChatPostRequest);
		restApi.get("/:roomId/history").handler(handleChatHistoryRequest);
		restApi.get("/:roomId/new/:lastMessageId").handler(handleChatMissedRequest);
		return restApi;
	}
	
	shared {String+} publishedAddresses => eventBus.publishedAddresses;
}