import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle
}
import io.vertx.ceylon.core.http {
	HttpServer
}
import io.vertx.ceylon.web {
	routerFactory=router
}
import io.vertx.ceylon.web.handler {
	staticHandler
}

final class HttpServerVerticle() extends Verticle() {
	
	value log = logger(`package`);
	variable HttpServer? server = null;
	
	shared actual void start() {
		value serverConfig = ServerConfiguration(config);
		value authRouterFactory = KeycloakAuthRouterFactory(vertx, serverConfig.hostname, serverConfig.port);
		value router = routerFactory.router(vertx);
		
		router.mountSubRouter("/", authRouterFactory.createUserSessionRouter(serverConfig.userSessionTimeout.milliseconds));
		
		router.route("/logs/*").handler(staticHandler.create("logs").setCachingEnabled(false).setDirectoryListing(true).handle);
		router.route("/static/*").handler(staticHandler.create("static").handle);
		router.route("/client/*").handler(staticHandler.create("client").handle);
		
		router.mountSubRouter("/eventbus", GameRoomEventBus(vertx).createEventBusRouter());
		router.mountSubRouter("/api", GameRoomRestApi(vertx).createRouter());
		
		router.mountSubRouter("/", authRouterFactory.createLoginRouter());
		router.mountSubRouter("/", GameRoomRouterFactory(vertx, serverConfig).createRouter());
		
		server = vertx.createHttpServer().requestHandler(router.accept).listen(serverConfig.port);
		
		log.info("Started webserver : http://``serverConfig.hostname``:``serverConfig.port``");
	}
	
	shared actual void stop() {
		value serverConfig = ServerConfiguration(config);
		if (exists currentServer = server) {
			currentServer.close();
		}
		log.info("Stopped webserver : http://``serverConfig.hostname``:``serverConfig.port``");
	}
}