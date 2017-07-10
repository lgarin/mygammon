import backgammon.server.util {
	JsonFile
}

import ceylon.json {
	Object
}

import io.vertx.ceylon.auth.oauth2 {
	OAuth2Auth,
	oAuth2Auth
}
import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.web {
	routerFactory=router,
	Router,
	Route
}
import io.vertx.ceylon.web.handler {
	userSessionHandler,
	cookieHandler,
	sessionHandler,
	oAuth2AuthHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}

final class KeycloakAuthRouterFactory(Vertx vertx, String hostname, Integer port) {
		
		variable OAuth2Auth? _oauth2 = null;
		variable Route? callbackRoute = null;
		
		function createOAuth2() {
			if (is Object config = JsonFile("resource/keycloak.json").readContent()) {
				return oAuth2Auth.createKeycloak(vertx, "AUTH_CODE", config);
			} else {
				throw Exception("Cannot parse resource/keycloak.json");
			}
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

		function createAuthHandler() {
			value authHandler = oAuth2AuthHandler.create(oauth2, "http://``hostname``:``port``");
			if (exists currentCallbackRoute = callbackRoute) {
				authHandler.setupCallback(currentCallbackRoute);
			}
			return authHandler.addAuthority("openid");
		}
		
		shared Router createUserSessionRouter(Integer sessionTimeout) {
			value router = routerFactory.router(vertx);
			callbackRoute = router.route("/callback");
			router.route().handler(createCookieHandler().handle);
			router.route().handler(createSessionHandler(sessionTimeout).handle);
			router.route().handler(createUserSessionHandler().handle);
			return router;
		}
		
		shared Router createLoginRouter() {
			value router = routerFactory.router(vertx);
			router.route().handler(createAuthHandler().handle);
			return router;
		}
}