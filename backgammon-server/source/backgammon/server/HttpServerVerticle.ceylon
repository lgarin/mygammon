import ceylon.json {
	Object
}

import io.vertx.ceylon.auth.shiro {
	shiroAuth,
	properties
}
import io.vertx.ceylon.core {
	Verticle
}
import io.vertx.ceylon.web {
	routerFactory=router,
	RoutingContext
}
import io.vertx.ceylon.web.handler {
	loggerHandler,
	templateHandler,
	cookieHandler,
	bodyHandler,
	sessionHandler,
	formLoginHandler,
	redirectAuthHandler,
	staticHandler
}
import io.vertx.ceylon.web.sstore {
	localSessionStore
}
import io.vertx.ceylon.web.templ {
	thymeleafTemplateEngine
}

shared class HttpServerVerticle() extends Verticle() {
	
	Integer bodyLimit = 100000;
	
	shared actual void start() {
		value router = routerFactory.router(vertx);
		value authProvider = shiroAuth.create(vertx, properties, Object {
			"properties_path" -> "file:auth.properties"
		});
		
		router.route().handler(cookieHandler.create().handle);
		router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);
		router.route().handler(sessionHandler.create(localSessionStore.create(vertx)).handle);
		
		router.route().handler(loggerHandler.create().handle);
		router.post("/login").handler(formLoginHandler.create(authProvider, "username", "password", "return_url", "/private/board.html").handle);
		router.route("/logout").handler {
			void requestHandler(RoutingContext routingContext) {
				routingContext.clearUser();
				routingContext.response().putHeader("location", "/").setStatusCode(302).end();
			}
		};
		
		//router.route().handler(templateHandler.create(thymeleafTemplateEngine.create(), "templates", "text/html").handle);
		router.route("/private/*").handler(redirectAuthHandler.create(authProvider, "/index.html", "return_url").handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		
		
		/*
		router.route("/success").handler {
			void requestHandler(RoutingContext routingContext) {
				value response = routingContext.response();
				response.putHeader("content-type", "text/plain");
				response.end("Hello World!!!");
			}
		};
		*/
		
		vertx.createHttpServer().requestHandler(router.accept).listen(8080);
	}
}