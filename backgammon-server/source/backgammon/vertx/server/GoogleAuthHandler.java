package backgammon.vertx.server;

import com.redhat.ceylon.compiler.java.metadata.Ceylon;
import com.redhat.ceylon.compiler.java.metadata.Ignore;
import com.redhat.ceylon.compiler.java.metadata.Name;
import com.redhat.ceylon.compiler.java.metadata.TypeInfo;
import com.redhat.ceylon.compiler.java.runtime.model.ReifiedType;
import com.redhat.ceylon.compiler.java.runtime.model.TypeDescriptor;

import io.vertx.core.AsyncResult;
import io.vertx.core.Handler;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.auth.User;
import io.vertx.ext.auth.oauth2.AccessToken;
import io.vertx.ext.auth.oauth2.OAuth2Auth;
import io.vertx.ext.web.Route;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.impl.AuthHandlerImpl;

@Ceylon(major = 8)
public class GoogleAuthHandler implements ReifiedType, io.vertx.ceylon.web.handler.AuthHandler  {

	  @Ignore public static final TypeDescriptor $TypeDescriptor$ = TypeDescriptor.klass(GoogleAuthHandler.class);
	  @Ignore private final GoogleAuthHandlerImpl delegate;

	  public GoogleAuthHandler(final @TypeInfo("io.vertx.ceylon.auth.oauth2::OAuth2Auth") @Name("oauth2") io.vertx.ceylon.auth.oauth2.OAuth2Auth oauth2, final @TypeInfo("ceylon.language::String") @Name("host") ceylon.language.String host) {
	    this.delegate = new GoogleAuthHandlerImpl(io.vertx.ceylon.auth.oauth2.OAuth2Auth.TO_JAVA.safeConvert(oauth2), io.vertx.lang.ceylon.ToJava.String.safeConvert(host));
	  }

	  @Ignore 
	  public TypeDescriptor $getType$() {
	    return $TypeDescriptor$;
	  }

	  @Ignore
	  public Object getDelegate() {
	    return delegate;
	  }

	  @TypeInfo("ceylon.language::Anything")
	  public void handle(
	    final @TypeInfo("io.vertx.ceylon.web::RoutingContext") @Name("arg0") io.vertx.ceylon.web.RoutingContext arg0) {
	    io.vertx.ext.web.RoutingContext arg_0 = io.vertx.ceylon.web.RoutingContext.TO_JAVA.safeConvert(arg0);
	    delegate.handle(arg_0);
	  }

	  @TypeInfo("io.vertx.ceylon.web.handler::AuthHandler")
	  public io.vertx.ceylon.web.handler.AuthHandler addAuthority(
	    final @TypeInfo("ceylon.language::String") @Name("authority") ceylon.language.String authority) {
	    java.lang.String arg_0 = io.vertx.lang.ceylon.ToJava.String.safeConvert(authority);
	    delegate.addAuthority(arg_0);
	    return this;
	  }

	  @TypeInfo("io.vertx.ceylon.web.handler::AuthHandler")
	  public io.vertx.ceylon.web.handler.AuthHandler addAuthorities(
	    final @TypeInfo("ceylon.language::Set<ceylon.language::String>") @Name("authorities") ceylon.language.Set<ceylon.language.String> authorities) {
	    java.util.Set<java.lang.String> arg_0 = io.vertx.lang.ceylon.ToJava.convertSet(authorities, io.vertx.lang.ceylon.ToJava.String);
	    delegate.addAuthorities(arg_0);
	    return this;
	  }

	  @TypeInfo("ceylon.language::String")
	  public ceylon.language.String authURI(
	    final @TypeInfo("ceylon.language::String") @Name("redirectURL") ceylon.language.String redirectURL, 
	    final @TypeInfo("ceylon.language::String") @Name("state") ceylon.language.String state) {
	    java.lang.String arg_0 = io.vertx.lang.ceylon.ToJava.String.safeConvert(redirectURL);
	    java.lang.String arg_1 = io.vertx.lang.ceylon.ToJava.String.safeConvert(state);
	    ceylon.language.String ret = io.vertx.lang.ceylon.ToCeylon.String.safeConvert(delegate.authURI(arg_0, arg_1));
	    return ret;
	  }

	  @TypeInfo("io.vertx.ceylon.web.handler::AuthHandler")
	  public GoogleAuthHandler setupCallback(
	    final @TypeInfo("io.vertx.ceylon.web::Route") @Name("route") io.vertx.ceylon.web.Route route) {
	    io.vertx.ext.web.Route arg_0 = io.vertx.ceylon.web.Route.TO_JAVA.safeConvert(route);
	    delegate.setupCallback(arg_0);
	    return this;
	  }
	  
	  private static final class GoogleAuthHandlerImpl extends AuthHandlerImpl {

			private final String host;

			private Route callback;

			public GoogleAuthHandlerImpl(OAuth2Auth authProvider, String host) {
				super(authProvider);
				this.host = host;
			}

			@Override
			public void handle(io.vertx.ext.web.RoutingContext ctx) {
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

			private String authURI(String redirectURL, String state) {
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

				return ((OAuth2Auth) authProvider).authorizeURL(
						new JsonObject().put("redirect_uri", host + callback.getPath())
								.put("scope", scopes.toString()).put("state", redirectURL));
			}

			
			
			public void setupCallback(Route route) {

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

						final String relative_redirect_uri = ctx.request().getParam("state");
						// for google the redirect uri must match the registered urls
						final String redirect_uri = host + callback.getPath();

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
			}
		}
}
