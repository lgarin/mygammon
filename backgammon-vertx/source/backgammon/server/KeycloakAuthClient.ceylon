import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.core.buffer {

	Buffer
}
import io.vertx.ceylon.web {

	RoutingContext
}
import io.vertx.ceylon.core.http {

	HttpClientResponse,
	HttpClientOptions,
	HttpClient
}
import backgammon.server.room {

	RoomConfiguration
}
import ceylon.json {

	Object
}

final class KeycloakUserInfo(Object json) {
	shared String displayName = json.getString("username");
	shared String userId => json.getString("sub");
}


final class KeycloakAuthClient(Vertx vertx, RoomConfiguration configuration) {

	value baseUrl = "``configuration.keycloakUrl``/realms/``configuration.keycloakRealm``/protocol/openid-connect";

	variable HttpClient? _httpClient = null;
	
	function createHttpClient() {
		value options = HttpClientOptions {
			ssl = false;
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
	
	shared void fetchUserInfo(RoutingContext context, void handler(KeycloakUserInfo? userInfo)) {
		if (exists token = context.user()) {
			makeRestCall {
				url = "``baseUrl``/userinfo";
				token = token.principal().getString("access_token");
				void bodyHandler(Buffer? body) {
					if (exists body) {
						handler(KeycloakUserInfo(body.toJsonObject()));
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
				url = "``baseUrl``/logout";
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