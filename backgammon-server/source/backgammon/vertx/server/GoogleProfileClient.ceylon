import ceylon.json {
	Object
}

import io.vertx.ceylon.auth.oauth2 {
	AccessToken
}
import io.vertx.ceylon.core.buffer {
	Buffer
}
import io.vertx.ceylon.core.http {
	HttpClient,
	HttpClientResponse
}
import io.vertx.ceylon.web {
	RoutingContext
}
class UserInfo(Object json, shared AccessToken accessToken) {
	shared String displayName = json.getString("displayName");
	shared String pictureUrl = json.getObject("image").getString("url");
}

class GoogleProfileClient(HttpClient httpClient) {
	
	shared void fetchUserInfo(RoutingContext context, void handler(UserInfo? userInfo)) {
		if (is AccessToken token = context.user()) {
			value request = httpClient.getAbs("https://www.googleapis.com/plus/v1/people/me?fields=displayName%2Cimage%2Furl&key=AIzaSyBCs5hbaFFCdz2fs8hc53s7XRLJXwhIq-4");
			request.headers().add("Authorization", "Bearer " + token.principal().getString("access_token"));
			request.handler {
				void handler(HttpClientResponse res) {
					if (res.statusCode() == 200) {
						res.bodyHandler {
							void bodyHandler(Buffer body) {
								handler(UserInfo(body.toJsonObject(), token));
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