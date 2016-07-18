import backgammon.common {
	OutboundTableMessage,
	OutboundMatchMessage,
	InboundRoomMessage,
	FindMatchTableMessage,
	PlayerInfo,
	RoomId,
	PlayerId,
	OutboundRoomMessage,
	EnterRoomMessage,
	EnteredRoomMessage,
	FoundMatchTableMessage,
	parseRoomMessage,
	formatRoomMessage,
	OutboundGameMessage,
	InboundGameMessage,
	parseGameMessage,
	TableStateRequestMessage,
	TableId,
	TableStateResponseMessage
}
import backgammon.server.common {
	RoomConfiguration
}
import backgammon.server.game {
	GameRoom
}
import backgammon.server.match {
	MatchRoom
}

import ceylon.json {
	Object,
	Value
}
import ceylon.logging {
	logger
}
import ceylon.time {
	Duration,
	now
}

import io.vertx.ceylon.auth.oauth2 {
	oAuth2Auth,
	OAuth2ClientOptions,
	OAuth2Auth
}
import io.vertx.ceylon.core {
	Verticle,
	Future,
	WorkerExecutor
}
import io.vertx.ceylon.core.eventbus {
	Message
}
import io.vertx.ceylon.core.http {
	HttpClientOptions,
	HttpClient,
	options,
	get,
	post,
	delete
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext,
	cookieFactory=cookie
}
import io.vertx.ceylon.web.handler {
	loggerHandler,
	cookieHandler,
	sessionHandler,
	staticHandler,
	corsHandler
}
import io.vertx.ceylon.web.handler.sockjs {
	SockJSHandlerOptions,
	BridgeOptions,
	PermittedOptions,
	sockJSHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}

shared final class HttpServerVerticle() extends Verticle() {
	
	value roomId = "test";
	value hostname = "localhost";
	value port = 8080;
	
	variable GoogleProfileClient? _googleProfileClient = null;
	variable HttpClient? _httpClient = null;
	variable OAuth2Auth? _oauth2 = null;
	
	function createOAuth2() {
		// Set the client credentials and the OAuth2 server
		value credentials = OAuth2ClientOptions {
			clientID = "890469788366-oangelno01k4ui5bvn2an4i217t8fjcf.apps.googleusercontent.com";
			clientSecret = "iLxAJ94s3d3kftW8DgbVU6H8";
			site = "https://accounts.google.com";
			tokenPath = "https://www.googleapis.com/oauth2/v3/token";
			authorizationPath = "/o/oauth2/auth";
		};
		return oAuth2Auth.create(vertx, "AUTH_CODE", credentials);
	}
	
	value oauth2 {
		return _oauth2 else (_oauth2 = createOAuth2());
	}
	
	function createHttpClient() {
		value options = HttpClientOptions {
			ssl = true;
			trustAll =  true;
		};
		return vertx.createHttpClient(options);
	}
	
	value httpClient {
		return _httpClient else (_httpClient = createHttpClient());
	}
	
	value googleProfileClient {
		return _googleProfileClient else (_googleProfileClient = GoogleProfileClient(httpClient));
	}
	
	function createSockJsHandler() {
		value sockJsOptions = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = {PermittedOptions { addressRegex = "^OutboundTableMessage-.*"; }, PermittedOptions { addressRegex = "^OutboundGameMessage-.*"; } };
		};
		return sockJSHandler.create(vertx, sockJsOptions).bridge(bridgeOptions);
	}
	
	void sendInboundRoomMessage<OutboundMessage>(InboundRoomMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies OutboundRoomMessage {
		vertx.eventBus().send("InboundRoomMessage-``message.roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
			if (is Throwable result) {
				responseHandler(result);
			} else if (exists body = result.body(), exists typeName = body.keys.first) {
				if (is OutboundMessage response = parseRoomMessage(typeName, body.getObject(typeName))) {
					responseHandler(response);
				} else {
					responseHandler(Exception("Invalid response type: ``typeName``"));
				}
			} else {
				responseHandler(Exception("Invalid response: ``result``"));
			}
		});
	}
	
	void handleStart(RoutingContext routingContext) {
		/*
		void handler(UserInfo? userInfo) {
			if (exists userInfo) {
				//session.put("userInfo", userInfo);
				routingContext.response().putHeader("Location", "static/board.html").setStatusCode(302).end();
			} else {
				routingContext.fail(Exception("No info returned for current user"));
			}
		}
		
		googleProfileClient.fetchUserInfo(routingContext, handler);
		 */
		value playerInfo = PlayerInfo("test1", "Lucien", "/static/images/unknown.png");
		routingContext.session()?.put("playerInfo", playerInfo);
		routingContext.addCookie(cookieFactory.cookie("playerInfo", playerInfo.toBase64()));
		
		sendInboundRoomMessage(EnterRoomMessage(PlayerId(playerInfo.id), RoomId(roomId), playerInfo), void (Throwable|EnteredRoomMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				routingContext.response().putHeader("Location", "/room/``roomId``/play").setStatusCode(302).end();
			}
		});
	}
	
	function getCurrentPlayerInfo(RoutingContext rc) => rc.session()?.get<PlayerInfo>("playerInfo");
	
	function getCurrentPlayerId(RoutingContext rc) {
		if (exists playerInfo = getCurrentPlayerInfo(rc)) {
			return PlayerId(playerInfo.id);
		} else {
			return null;
		}
	}
	
	function getRequestRoomId(RoutingContext rc) {
		if (exists roomId = rc.request().getParam("roomId")) {
			return RoomId(roomId);
		} else {
			return null;
		}
	}
	
	function getRequestTableId(RoutingContext rc) {
		if (exists roomId = rc.request().getParam("roomId"), exists table = rc.request().getParam("tableIndex")) {
			if (exists tableIndex = parseInteger(table)) {
				return TableId(roomId, tableIndex);
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	void handlePlay(RoutingContext routingContext) {
		if (exists playerId = getCurrentPlayerId(routingContext), exists roomId = getRequestRoomId(routingContext)) {
			sendInboundRoomMessage(FindMatchTableMessage(playerId, roomId), void (Throwable|FoundMatchTableMessage result) {
				if (is Throwable result) {
					routingContext.fail(result);
				} else if (exists table = result.table) {
					routingContext.response().putHeader("Location", "/room/``roomId``/table/``table``").setStatusCode(302).end();
				} else {
					routingContext.fail(503);
				}
			});
		} else {
			routingContext.response().putHeader("Location", "/start").setStatusCode(302).end();
		}
	}
	
	void handleTable(RoutingContext routingContext) {
		routingContext.reroute("static/board.html");
	}
	
	function createCorsHandler() { 
		value handler = corsHandler.create("http://``hostname``:``port``");
		handler.allowCredentials(true);
		handler.allowedMethod(options);
		handler.allowedMethod(get);
		handler.allowedMethod(post);
		handler.allowedMethod(delete);
		handler.allowedHeader("Authorization");
		handler.allowedHeader("www-authenticate");		 
		handler.allowedHeader("Content-Type");
		return handler;
	}
	
	void writeJsonResponse(RoutingContext rc, Object json) {
		value response = json.string;
		rc.response().headers().add("Content-Length", response.size.string);
		rc.response().headers().add("Content-Type", "application/json");
		rc.response().write(response).end();
	}
	
	
	
	void handleTableStateRequest(RoutingContext rc) {
		if (exists tableId = getRequestTableId(rc), exists playerId = getCurrentPlayerId(rc)) {
			sendInboundRoomMessage(TableStateRequestMessage(playerId, tableId), void (Throwable|TableStateResponseMessage result) {
				if (is Throwable result) {
					rc.fail(result);
				} else {
					writeJsonResponse(rc, result.toJson());
				}
			});
		} else {
			rc.fail(Exception("Invalid request: ``rc.request().uri``"));
		}
	}
	
	function createRestApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/table/:tableIndex/state").handler(handleTableStateRequest);
		return restApi;
	}
	
	void startHttp() {
		value router = routerFactory.router(vertx);
		value loginHandler = GoogleAuthHandler(oauth2, "http://``hostname``:``port``").setupCallback(router.route("/callback")).addAuthority("profile");
		//router.route().handler(createCorsHandler().handle);
		router.route().handler(cookieHandler.create().handle);
		//router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);		router.route().handler(sessionHandler.create(localSessionStore.create(vertx)).setNagHttps(false).handle);
		router.route().handler(loggerHandler.create().handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.route("/eventbus/*").handler(createSockJsHandler().handle);
		//router.route("/*").handler(loginHandler.handle);
		router.route("/start").handler(handleStart);
		router.route("/room/:roomId/play").handler(handlePlay);
		router.route("/room/:roomId/table/:tableId").handler(handleTable);
		router.mountSubRouter("/api", createRestApiRouter());
		vertx.createHttpServer().requestHandler(router.accept).listen(port);
		
		logger(`package`).info("Started http://``hostname``:``port``");
	}
	
	void registerParallelConsumer(WorkerExecutor executor, String address, Value process(Object msg)) {
		vertx.eventBus().consumer(address, void (Message<Object> message) {
			if (exists body = message.body()) {
				executor.executeBlocking(
					void (Future<Value> result) {
						result.complete(process(body));
					},
					void (Throwable|Value result) {
						if (is Throwable result) {
							message.fail(500, "Error: ``result.message``");
						} else {
							message.reply(result);
						}
					});
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
	}
	
	void startRoom() {
		// TODO read config from vertx.getOrCreateContext().config() 
		value config = RoomConfiguration(roomId, 100, Duration(60000), Duration(30000));
		value executor = vertx.createSharedWorkerExecutor("room-``roomId``");
		
		value matchRoom = MatchRoom(config, void (OutboundTableMessage|OutboundMatchMessage msg) {
			logger(`package`).info(formatRoomMessage(msg).string);
			vertx.eventBus().send("OutboundTableMessage-``msg.tableId``", formatRoomMessage(msg));
		});
		
		registerParallelConsumer(executor, "InboundRoomMessage-``roomId``", function (Object msg) {
			logger(`package`).info(msg.string);
			if (exists typeName = msg.keys.first) {
				if (is InboundRoomMessage request = parseRoomMessage(typeName, msg.getObject(typeName))) {
					value response = matchRoom.processRoomMessage(request, now());
					return formatRoomMessage(response);
				} else {
					throw Exception("Invalid request type: ``typeName``");
				}
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
		
		value gameRoom = GameRoom(config, void (OutboundGameMessage msg) {
			logger(`package`).info(formatRoomMessage(msg).string);
			vertx.eventBus().send("OutboundGameMessage-``msg.matchId``", formatRoomMessage(msg));
		});
		
		registerParallelConsumer(executor, "InboundGameMessage-``roomId``",  function (Object msg) {
			logger(`package`).info(msg.string);
			if (exists typeName = msg.keys.first) {
				if (is InboundGameMessage request = parseGameMessage(typeName, msg.getObject(typeName))) {
					return gameRoom.processGameMessage(request, now());
				} else {
					throw Exception("Invalid request type: ``typeName``");
				}
			} else {
				throw Exception("Invalid request: ``msg``");
			}
		});
		
		vertx.setPeriodic(config.gameInactiveTimeout.milliseconds, void (Integer val) {
			value currentTime = now();
			matchRoom.removeInactivePlayers(currentTime);
			gameRoom.removeInactiveGames(currentTime);
		});
		
		logger(`package`).info("Started room ``roomId``");
	}

	shared actual void start() {
		startHttp();
		startRoom();
	}
}