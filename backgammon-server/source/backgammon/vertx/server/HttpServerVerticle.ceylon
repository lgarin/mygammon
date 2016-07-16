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
	parseFoundMatchTableMessage,
	parseFindMatchTableMessage,
	parseEnterRoomMessage,
	parseEnteredRoomMessage,
	RoomMessage
}
import backgammon.server.common {
	RoomConfiguration
}
import backgammon.server.match {
	MatchRoom
}

import ceylon.json {
	Object
}
import ceylon.language.meta {
	type
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
	Verticle
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
	RoutingContext
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
	
	value roomId = "Room1";
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
		value options = SockJSHandlerOptions {
			heartbeatInterval = 2000;
		};
		
		value bridgeOptions = BridgeOptions {
			outboundPermitteds = {PermittedOptions { address = "msg.to.client"; } };
		};
		return sockJSHandler.create(vertx).bridge(bridgeOptions);
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
		sendRoomMessage(EnterRoomMessage(PlayerId(playerInfo.id), RoomId(roomId), playerInfo), void (Throwable|EnteredRoomMessage result) {
			if (is Throwable result) {
				routingContext.fail(result);
			} else {
				routingContext.response().putHeader("Location", "/play").setStatusCode(302).end();
			}
		});
	}
	
	void handlePlay(RoutingContext routingContext) {
		if (exists playerInfo = routingContext.session()?.get<PlayerInfo>("playerInfo")) {
			sendRoomMessage(FindMatchTableMessage(PlayerId(playerInfo.id), RoomId(roomId)), void (Throwable|FoundMatchTableMessage result) {
				if (is Throwable result) {
					routingContext.fail(result);
				} else if (exists table = result.table) {
					routingContext.response().putHeader("Location", "/table/``table``").setStatusCode(302).end();
				} else {
					routingContext.fail(Exception("No table found"));
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
	
	function createRestApiRouter() {
		value eb = vertx.eventBus();
		value restApi = routerFactory.router(vertx);
		restApi.get("/room/:roomId/enter").handler((RoutingContext rc) {
			if (exists roomId = rc.pathParam("roomId"), exists playerInfo = rc.session()?.get<PlayerInfo>("playerInfo")) {
				rc.response().headers().add("Content-Type", "application/json");
				eb.send("InboundRoomMessage-``roomId``", EnterRoomMessage(PlayerId(playerInfo.id), RoomId(roomId), playerInfo), void (Throwable|Message<OutboundRoomMessage> result) {
					if (is Throwable result) {
						rc.fail(result);
					} else if (exists body = result.body()) {
						rc.response().write(body.toJson().string).end();
					}
				});
			} else {
				rc.fail(Exception("No room parameter"));
			}
		});
		restApi.get("/room/:roomId/findMatchTable").handler((RoutingContext rc) {
			if (exists roomId = rc.pathParam("roomId"), exists playerInfo = rc.session()?.get<PlayerInfo>("playerInfo")) {
				rc.response().headers().add("Content-Type", "application/json");
				eb.send("InboundRoomMessage-``roomId``", FindMatchTableMessage(PlayerId(playerInfo.id), RoomId(roomId)), void (Throwable|Message<OutboundRoomMessage> result) {
					if (is Throwable result) {
						rc.fail(result);
					} else if (exists body = result.body()) {
						rc.response().write(body.toJson().string).end();
					}
				});
			} else {
				rc.fail(Exception("No room parameter"));
			}
		});
		return restApi;
	}
	
	void startHttp() {
		value router = routerFactory.router(vertx);
		value loginHandler = GoogleAuthHandler(oauth2, "http://``hostname``:``port``").setupCallback(router.route("/callback")).addAuthority("profile");
		//router.route().handler(createCorsHandler().handle);
		router.route().handler(cookieHandler.create().handle);
		//router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);		router.route().handler(sessionHandler.create(localSessionStore.create(vertx)).handle);
		router.route().handler(loggerHandler.create().handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.route("/eventbus/*").handler(createSockJsHandler().handle);
		//router.route("/*").handler(loginHandler.handle);
		router.route("/start").handler(handleStart);
		router.route("/play").handler(handlePlay);
		router.route("/table/:tableId").handler(handleTable);
		router.mountSubRouter("/api", createRestApiRouter());
		vertx.createHttpServer().requestHandler(router.accept).listen(port);
		
		logger(`package`).info("Started http://``hostname``:``port``");
	}
	
	// TODO move in RoomMessage source file
	function formatRoomMessage(RoomMessage message) {
		return Object({type(message).declaration.name -> message.toJson()});
	}
	
	// TODO move in RoomMessage source file
	function parseRoomMessage(String typeName, Object json) {
		if (typeName == `class EnterRoomMessage`.name) {
			return parseEnterRoomMessage(json);
		} else if (typeName == `class EnteredRoomMessage`.name) {
			return parseEnteredRoomMessage(json);
		} else if (typeName == `class FindMatchTableMessage`.name) {
			return parseFindMatchTableMessage(json);
		} else if (typeName == `class FoundMatchTableMessage`.name) {
			return parseFoundMatchTableMessage(json);
		} else {
			return Exception("No parser found for type ``typeName``");
		}
	}
	
	void startRoom() {
		value eb = vertx.eventBus();
		value config = RoomConfiguration(roomId, 100, Duration(60000), Duration(30000));
		void handler(OutboundTableMessage|OutboundMatchMessage msg) {
			eb.send(config.roomName, msg.string);
		}
		
		value room = MatchRoom(config, handler);
		
		eb.consumer("InboundRoomMessage-``roomId``", void (Message<Object> message) {
			if (exists body = message.body(), exists typeName = body.keys.first) {
				if (is InboundRoomMessage request = parseRoomMessage(typeName, body.getObject(typeName))) {
					value response = room.processPlayerMessage(request, now());
					message.reply(formatRoomMessage(response));
				} else {
					message.fail(500, "Invalid request type: ``typeName``");
				}
			} else {
				message.fail(500, "Invalid request: ``message``");
			}
		});
		
		vertx.setPeriodic(1000, (Integer val) => eb.publish("msg.to.client", "hello"));
		logger(`package`).info("Started ``roomId``");
	}

	void sendRoomMessage<OutboundMessage>(InboundRoomMessage message, void responseHandler(Throwable|OutboundMessage response)) given OutboundMessage satisfies OutboundRoomMessage {
		value eb = vertx.eventBus();
		eb.send("InboundRoomMessage-``roomId``", formatRoomMessage(message), void (Throwable|Message<Object> result) {
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

	shared actual void start() {
		startHttp();
		startRoom();
	}
}