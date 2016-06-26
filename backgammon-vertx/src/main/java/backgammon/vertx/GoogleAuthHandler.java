package backgammon.vertx;

import io.vertx.core.AsyncResult;
import io.vertx.core.Handler;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.auth.User;
import io.vertx.ext.auth.oauth2.AccessToken;
import io.vertx.ext.auth.oauth2.OAuth2Auth;
import io.vertx.ext.web.Route;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.OAuth2AuthHandler;
import io.vertx.ext.web.handler.impl.AuthHandlerImpl;

public class GoogleAuthHandler extends AuthHandlerImpl implements OAuth2AuthHandler {

	private final OAuth2Auth oauth2;
	private final String host;

	private Route callback;

	public GoogleAuthHandler(OAuth2Auth authProvider, String host) {
		super(authProvider);
		this.oauth2 = authProvider;
		this.host = host;
	}

	@Override
	public void handle(RoutingContext ctx) {
		User user = ctx.user();
		if (user != null) {
			// Already authenticated.

			// if this provider support JWT authorize
			if (oauth2.hasJWTToken()) {
				authorise(user, ctx);
			} else {
				// oauth2 used only for authentication (with or without scopes)
				ctx.next();
			}

		} else {
			// redirect request to the oauth2 server
			ctx.response().putHeader("Location", authURI(ctx.normalisedPath(), (String) ctx.get("state")))
					.setStatusCode(302).end();
		}
	}

	@Override
	public String authURI(String redirectURL, String state) {
		if (callback == null) {
			throw new NullPointerException("callback is null");
		}

		StringBuilder scopes = new StringBuilder();
		for (String authority : authorities) {
			scopes.append(authority);
			scopes.append(',');
		}

		// exclude the trailing comma
		if (scopes.length() > 0) {
			scopes.setLength(scopes.length() - 1);
		}

		return oauth2.authorizeURL(new JsonObject().put("redirect_uri", host + callback.getPath())
				.put("scope", scopes.toString()).put("state", redirectURL));
	}

	private void handleCallback(RoutingContext ctx) {
		// Handle the callback of the flow
		final String code = ctx.request().getParam("code");

		// code is a require value
		if (code == null) {
			ctx.fail(400);
			return;
		}

		final String relative_redirect_uri = ctx.request().getParam("state");
		// for google the redirect uri must match the registered urls
		final String redirect_uri = host + callback.getPath();

		oauth2.getToken(new JsonObject().put("code", code).put("redirect_uri", redirect_uri), res -> {
			if (res.failed()) {
				ctx.fail(res.cause());
			} else {
				ctx.setUser(res.result());
				ctx.reroute(relative_redirect_uri);
			}
		});
	}

	@Override
	public OAuth2AuthHandler setupCallback(Route route) {

		this.callback = route;
		route.handler(this::handleCallback);
		return this;
	}
}
