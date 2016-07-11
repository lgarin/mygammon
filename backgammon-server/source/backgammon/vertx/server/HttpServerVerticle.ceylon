import backgammon.common {
	OutboundTableMessage,
	OutboundMatchMessage
}
import backgammon.server.common {
	RoomConfiguration
}
import backgammon.server.match {
	MatchRoom
}

import ceylon.logging {
	logger
}
import ceylon.time {
	Duration
}

import io.vertx.ceylon.auth.oauth2 {
	oAuth2Auth,
	OAuth2ClientOptions,
	OAuth2Auth
}
import io.vertx.ceylon.core {
	Verticle
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
import io.vertx.ceylon.core.eventbus {

	Message
}

shared class HttpServerVerticle() extends Verticle() {
	
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
		routingContext.session()?.put("userInfo", "test");
		routingContext.response().putHeader("Location", "static/board.html").setStatusCode(302).end();
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
		value restApi = routerFactory.router(vertx);
		restApi.get("/products/:productID").handler((RoutingContext rc) {
			
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
		router.mountSubRouter("/api", createRestApiRouter());
		vertx.createHttpServer().requestHandler(router.accept).listen(port);
		
		logger(`package`).info("Started http://``hostname``:``port``");
	}
	
	void startRoom(String roomId) {
		value eb = vertx.eventBus();
		value config = RoomConfiguration(roomId, 100, Duration(60000), Duration(30000));
		void handler(OutboundTableMessage|OutboundMatchMessage msg) {
			eb.send(config.roomName, msg.string);
		}
		
		value room = MatchRoom(config, handler);
		
		vertx.setPeriodic(1000, (Integer val) => eb.publish("msg.to.client", "hello"));
		logger(`package`).info("Started ``roomId``");
	}
	
	shared actual void start() {
		startHttp();
		startRoom("Room1");
	}
}