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
	HttpClient
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext
}
import io.vertx.ceylon.web.handler {
	loggerHandler,
	cookieHandler,
	sessionHandler,
	staticHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}

shared class HttpServerVerticle() extends Verticle() {
	
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
	
	void handleStart(RoutingContext routingContext) {
		void handler(UserInfo? userInfo) {
			if (exists userInfo, exists session = routingContext.session()) {
				session.put("userInfo", userInfo);
				routingContext.response().putHeader("Location", "static/board.html").setStatusCode(302).end();
			} else {
				routingContext.fail(Exception("No info returned for current user"));
			}
		}
		
		googleProfileClient.fetchUserInfo(routingContext, handler);
	}
	
	shared actual void start() {
		value router = routerFactory.router(vertx);
		value loginHandler = GoogleAuthHandler(oauth2, "http://localhost:8080").setupCallback(router.route("/callback")).addAuthority("profile");
		
		router.route().handler(cookieHandler.create().handle);
		//router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);
		router.route().handler(sessionHandler.create(localSessionStore.create(vertx)).handle);
		router.route().handler(loggerHandler.create().handle);
		
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/modules/*").handler(staticHandler.create("modules").handle);
		router.route("/*").handler(loginHandler.handle);
		router.route("/start").handler(handleStart);
		
		vertx.createHttpServer().requestHandler(router.accept).listen(8080);
	}
}