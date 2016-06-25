package backgammon.vertx.server;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

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

public class GoogleAuthHandler extends AuthHandlerImpl implements OAuth2AuthHandler, Handler<RoutingContext> {

	private final String host;

	private Route callback;

	public GoogleAuthHandler(OAuth2Auth authProvider, String host) {
		super(authProvider);
		this.host = host;
	}

	@Override
	public void handle(RoutingContext ctx) {
		User user = ctx.user();
		if (user != null) {
			// Already authenticated.

			// if this provider support JWT authorize
			if (((OAuth2Auth) authProvider).hasJWTToken()) {
				authorise(user, ctx);
			} else {
				// oauth2 used only for authentication (with or without scopes)
				ctx.next();
			}

		} else {
			// redirect request to the oauth2 server
			ctx.response().putHeader("Location", authURI(ctx.normalisedPath(), (String) ctx.get("state"))).setStatusCode(302)
					.end();
		}
	}

	@Override
	public String authURI(String redirectURL, String state) {
		if (callback == null) {
			throw new NullPointerException("callback is null");
		}

		StringBuilder scopes = new StringBuilder();

		try {
			for (String authority : authorities) {
				scopes.append(URLEncoder.encode(authority, "UTF-8"));
				scopes.append(',');
			}
		} catch (UnsupportedEncodingException e) {
			throw new RuntimeException(e);
		}

		// exclude the trailing comma
		if (scopes.length() > 0) {
			scopes.setLength(scopes.length() - 1);
		}

		return ((OAuth2Auth) authProvider).authorizeURL(
				new JsonObject().put("redirect_uri", host + callback.getPath() + "?redirect_uri=" + redirectURL)
						.put("scope", scopes.toString()).put("state", state));
	}

	
	
	@Override
	public OAuth2AuthHandler setupCallback(Route route) {

		this.callback = route;

		route.handler(new Handler<RoutingContext>() {
			
			@Override
			public void handle(final RoutingContext ctx) {
				// Handle the callback of the flow
				final String code = ctx.request().getParam("code");

				// code is a require value
				if (code == null) {
					ctx.fail(400);
					return;
				}

				final String relative_redirect_uri = ctx.request().getParam("redirect_uri");
				// for google the redirect uri must match the registered urls
				final String redirect_uri = host + callback.getPath() + "?redirect_uri=" + relative_redirect_uri;

				((OAuth2Auth) authProvider).getToken(new JsonObject().put("code", code).put("redirect_uri", redirect_uri),
						new Handler<AsyncResult<AccessToken>>() {
							public void handle(AsyncResult<AccessToken> res) {
								if (res.failed()) {
									ctx.fail(res.cause());
								} else {
									ctx.setUser(res.result());
									ctx.reroute(relative_redirect_uri);
								}
							}
						});
				
			}
		});

		return this;
	}
}
