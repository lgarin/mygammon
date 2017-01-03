import ceylon.json {
	Object
}

import io.vertx.ceylon.core {
	Vertx
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

final class GoogleUserInfo(Object json) {
	shared String displayName = json.getString("displayName");
	// TODO use regex instead of replace
	shared String pictureUrl = json.getObject("image").getString("url").replace("sz=50", "sz=100");
	shared String iconUrl = json.getObject("image").getString("url").replace("sz=50", "sz=25");
	shared String userId => json.getString("id");
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
	
	void makeRestCall(String url, String token, void bodyHandler(Buffer? body)) {
		value request = httpClient.getAbs(url);
		request.headers().add("Authorization", "Bearer ``token``");
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					res.bodyHandler(bodyHandler);
				} else {
					bodyHandler(null);
				}
			}
		};
		request.end();
	}
	
	shared void fetchUserInfo(RoutingContext context, void handler(GoogleUserInfo? userInfo)) {
		if (exists token = context.user()) {
			makeRestCall {
				url = "https://www.googleapis.com/plus/v1/people/me?fields=displayName%2Cimage%2Furl%2Cid&key=``googleApiKey``";
				token = token.principal().getString("access_token");
				void bodyHandler(Buffer? body) {
					if (exists body) {
						handler(GoogleUserInfo(body.toJsonObject()));
					} else {
						handler(null);
					}
				}
			};
		} else {
			handler(null);
		}
	}
	
	shared void logout(RoutingContext context, void handler(Boolean success)) {
		if (exists token = context.user()) {
			makeRestCall {
				url = "https://accounts.google.com/o/oauth2/revoke?token=``token.principal().getString("access_token")``";
				token = token.principal().getString("access_token");
				void bodyHandler(Buffer? body) {
					if (exists body) {
						handler(true);
					} else {
						handler(false);
					}
				}
			};
		} else {
			handler(false);
		}
	}
}