import ceylon.json {
	Object
}
import io.vertx.ceylon.auth.common {
	User
}
import io.vertx.ceylon.core.buffer {
	Buffer
}
import io.vertx.ceylon.core.http {
	HttpClient,
	HttpClientResponse,
	HttpClientOptions
}
import io.vertx.ceylon.web {
	RoutingContext
}
import io.vertx.ceylon.core {
	Vertx
}

final class GoogleUserInfo(Object json, User token) {
	shared String displayName = json.getString("displayName");
	// TODO use regex instead of replace
	shared String pictureUrl = json.getObject("image").getString("url").replace("sz=50", "sz=100");
	shared String iconUrl = json.getObject("image").getString("url").replace("sz=50", "sz=25");
	shared String userId => token.principal().getString("access_token");
}

final class GoogleProfileClient(Vertx vertx) {
	
	value googleApiKey = "AIzaSyBCs5hbaFFCdz2fs8hc53s7XRLJXwhIq-4";
	
	variable HttpClient? _httpClient = null;
	
	function createHttpClient() {
		value options = HttpClientOptions {
			ssl = true;
			trustAll =  true;
		};
		return vertx.createHttpClient(options);
	}
	
	value httpClient {
		return _httpClient else (_httpClient = createHttpClient());
	}
	
	shared void fetchUserInfo(RoutingContext context, void handler(GoogleUserInfo? userInfo)) {
		if (exists token = context.user()) {
			value request = httpClient.getAbs("https://www.googleapis.com/plus/v1/people/me?fields=displayName%2Cimage%2Furl&key=``googleApiKey``");
			request.headers().add("Authorization", "Bearer " + token.principal().getString("access_token"));
			request.handler {
				void handler(HttpClientResponse res) {
					if (res.statusCode() == 200) {
						res.bodyHandler {
							void bodyHandler(Buffer body) {
								handler(GoogleUserInfo(body.toJsonObject(), token));
							}
						};
					} else {
						handler(null);
					}
				}
			};
			request.end();
		} else {
			handler(null);
		}
	}
}