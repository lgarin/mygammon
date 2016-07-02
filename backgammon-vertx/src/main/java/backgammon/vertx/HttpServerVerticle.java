package backgammon.vertx;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.core.http.HttpClient;
import io.vertx.core.http.HttpClientOptions;
import io.vertx.ext.auth.oauth2.OAuth2Auth;
import io.vertx.ext.auth.oauth2.OAuth2ClientOptions;
import io.vertx.ext.auth.oauth2.OAuth2FlowType;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.CookieHandler;
import io.vertx.ext.web.handler.LoggerHandler;
import io.vertx.ext.web.handler.OAuth2AuthHandler;
import io.vertx.ext.web.handler.SessionHandler;
import io.vertx.ext.web.handler.StaticHandler;
import io.vertx.ext.web.sstore.LocalSessionStore;

public class HttpServerVerticle extends AbstractVerticle {

	private GoogleProfileClient googleProfileClient;
	
	private OAuth2AuthHandler oauth2() {
		// Set the client credentials and the OAuth2 server
		OAuth2ClientOptions credentials = new OAuth2ClientOptions();
		credentials.setClientID("890469788366-oangelno01k4ui5bvn2an4i217t8fjcf.apps.googleusercontent.com");
		credentials.setClientSecret("iLxAJ94s3d3kftW8DgbVU6H8");
		credentials.setSite("https://accounts.google.com");
		credentials.setTokenPath("https://www.googleapis.com/oauth2/v3/token");
		credentials.setAuthorizationPath("/o/oauth2/auth");
		return new GoogleAuthHandler(OAuth2Auth.create(vertx, OAuth2FlowType.AUTH_CODE, credentials), "http://localhost:8080");
	}

	private HttpClient httpClient() {
		HttpClientOptions options = new HttpClientOptions();
		options.setSsl(true);
		options.setTrustAll(true);
		return vertx.createHttpClient(options);
	}
	
	private void handleStart(RoutingContext routingContext) {
		googleProfileClient.fetchUserInfo(routingContext, userInfo -> {
			if (userInfo == null) {
				routingContext.fail(new Exception("No info returned for current user"));
			} else {
				routingContext.session().put("userInfo", userInfo);
				//routingContext.reroute("/static/board.html");
				routingContext.response().putHeader("Location", "static/board.html").setStatusCode(302).end();
			}
		});
	}
	
	private void handleGame(RoutingContext routingContext) {
		if (routingContext.session().get("userInfo") != null) {
			routingContext.reroute("/static/board.html");
		} else {
			routingContext.response().putHeader("Location", "/start").setStatusCode(302).end();
		}
	}
	
	@Override
	public void start(Future<Void> fut) {
		Router router = Router.router(vertx);
		OAuth2AuthHandler loginHandler = oauth2().setupCallback(router.route("/callback"));
		loginHandler.addAuthority("profile");

		HttpClient httpClient = httpClient();
		googleProfileClient = new GoogleProfileClient(httpClient);
		
		router.route().handler(CookieHandler.create());
		// router.route().handler(bodyHandler.create().setBodyLimit(bodyLimit).handle);
		router.route().handler(SessionHandler.create(LocalSessionStore.create(vertx)));
		router.route().handler(LoggerHandler.create());

		router.route("/static/*").handler(StaticHandler.create("static").setCachingEnabled(false));
		router.route("/*").handler(loginHandler);
		
		router.route("/start").handler(this::handleStart);
		router.route("/game").handler(this::handleGame);

		vertx.createHttpServer().requestHandler(router::accept).listen(8080);
	}

}