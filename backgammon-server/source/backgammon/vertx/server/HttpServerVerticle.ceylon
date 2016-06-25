import ceylon.json { JsonObject=Object }

import io.vertx.ceylon.core {
	Verticle
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext
}
import io.vertx.ceylon.web.handler {
	loggerHandler,
	cookieHandler,
	bodyHandler,
	sessionHandler,
	formLoginHandler,
	redirectAuthHandler,
	staticHandler,
	oAuth2AuthHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}
import io.vertx.ceylon.auth.oauth2 {

	oAuth2Auth,
	OAuth2ClientOptions
}
import ceylon.logging {

	logger
}

shared class HttpServerVerticle() extends Verticle() {
	
	Integer bodyLimit = 100000;
	
	value oauth2 {
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
	
	shared actual void start() {
		value router = routerFactory.router(vertx);
		value loginHandler = oAuth2AuthHandler.create(oauth2, "http://localhost:8080").setupCallback(router.route("/callback"));
		loginHandler.addAuthority("profile");
		
		router.route().handler(cookieHandler.create().handle);
		//router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);
		router.route().handler(sessionHandler.create(localSessionStore.create(vertx)).handle);
		router.route().handler(loggerHandler.create().handle);
		
		//router.post("/login").handler(formLoginHandler.create(authProvider, "username", "password", "return_url", "/private/board.html").handle);
		router.route("/logout").handler {
			void requestHandler(RoutingContext routingContext) {
				routingContext.clearUser();
				routingContext.response().putHeader("location", "/").setStatusCode(302).end();
			}
		};
		
		//router.route().handler(templateHandler.create(thymeleafTemplateEngine.create(), "templates", "text/html").handle);
		router.route("/private/*").handler(loginHandler.handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		
		
		
		router.route("/private/success").handler {
			void requestHandler(RoutingContext routingContext) {
				value response = routingContext.response();
				//response.putHeader("Location", "https://www.googleapis.com/plus/v1/people/me?fields=image%2Furl&key=AIzaSyBCs5hbaFFCdz2fs8hc53s7XRLJXwhIq-4");
				//response.setStatusCode(302).end();
				if (exists user = routingContext.user()) {
					logger(`module`).info(user.principal().pretty);
				}
				response.putHeader("content-type", "text/plain");
				response.end("Hello World!!!");
			}
		};
		
		
		vertx.createHttpServer().requestHandler(router.accept).listen(8080);
	}
}