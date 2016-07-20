import io.vertx.ceylon.auth.oauth2 {
	OAuth2ClientOptions,
	OAuth2Auth,
	oAuth2Auth
}
import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	Route,
	routerFactory=router,
	Router
}
import io.vertx.ceylon.web.handler {
	cookieHandler,
	userSessionHandler,
	sessionHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}

final class GoogleAuthRouterFactory(Vertx vertx, String hostname, Integer port) {
		
		variable OAuth2Auth? _oauth2 = null;
		variable Route? callbackRoute = null;
		
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
		
		function createCookieHandler() {
			return cookieHandler.create();
		}
		
		function createSessionHandler(Integer sessionTimeout) {
			return sessionHandler.create(localSessionStore.create(vertx)).setSessionTimeout(sessionTimeout).setNagHttps(false);
		}
		
		function createUserSessionHandler() {
			return userSessionHandler.create(oauth2);
		}

		function createGoogleAuthHandler() {
			value authHandler = GoogleAuthHandler(oauth2, "http://``hostname``:``port``");
			if (exists currentCallbackRoute = callbackRoute) {
				authHandler.setupCallback(currentCallbackRoute);
			}
			return authHandler.addAuthority("profile");
		}
		
		shared Router createUserSessionRouter(Integer sessionTimeout) {
			value router = routerFactory.router(vertx);
			callbackRoute = router.route("/callback");
			router.route().handler(createCookieHandler().handle);
			router.route().handler(createSessionHandler(sessionTimeout).handle);
			router.route().handler(createUserSessionHandler().handle);
			return router;
		}
		
		shared Router createGoogleLoginRouter() {
			value router = routerFactory.router(vertx);
			router.route().handler(createGoogleAuthHandler().handle);
			return router;
		}
}