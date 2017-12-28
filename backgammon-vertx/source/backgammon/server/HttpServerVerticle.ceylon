import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle,
	Future
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
import backgammon.server.bus {

	GameRoomEventBus
}

final class HttpServerVerticle() extends Verticle() {
	
	value log = logger(`package`);
	variable HttpServer? server = null;
	
	shared actual void startAsync(Future<Anything> startFuture) {
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
		
		vertx.createHttpServer().requestHandler(router.accept).listen(serverConfig.port, (result) {
			if (is HttpServer result) {
				server = result;
				log.info("Started webserver : http://``serverConfig.hostname``:``serverConfig.port``");
				startFuture.complete();
			} else {
				startFuture.fail(result);
			}
		});
	}
	
	shared actual void stop() {
		value serverConfig = ServerConfiguration(config);
		if (exists currentServer = server) {
			currentServer.close();
		}
		log.info("Stopped webserver : http://``serverConfig.hostname``:``serverConfig.port``");
	}
}