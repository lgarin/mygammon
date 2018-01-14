import ceylon.json {
	Object,
	parse
}

import io.vertx.ceylon.core {
	Vertx
}
import io.vertx.ceylon.core.buffer {
	Buffer
}
import io.vertx.ceylon.core.http {
	HttpClientResponse,
	HttpClientOptions,
	HttpClient
}
import io.vertx.ceylon.web {
	RoutingContext
}
import java.util {

	Base64
}

import java.lang {
	JString=String
}

final shared class KeycloakUserInfo(Object json) {
	shared String displayName = json.getString("preferred_username");
	shared String userId = json.getString("sub");
}


final shared class KeycloakAuthClient(Vertx vertx, String baseUrl) {

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
	
	void makeRestCall(String url, String token, void bodyHandler(Buffer|Throwable body)) {
		value request = httpClient.getAbs(url);
		request.exceptionHandler(bodyHandler);
		request.headers().add("Authorization", "Bearer ``token``");
		request.handler {
			void handler(HttpClientResponse res) {
				if (res.statusCode() == 200) {
					res.bodyHandler(bodyHandler);
				} else {
					bodyHandler(Exception("GET to ``url`` returned ``res.statusCode()`` : ``res.statusMessage()``"));
				}
			}
		};
		request.end();
	}
	
	function decodeUserInfo(String accessToken) {
		if (exists encodedInfo = accessToken.split('.'.equals).getFromFirst(1)) {
			value decodedToken = JString(Base64.decoder.decode(encodedInfo), "UTF-8");
			return parse(decodedToken.string);
		} else {
			return null;
		}
	}

	shared void fetchUserInfo(RoutingContext context, void handler(KeycloakUserInfo|Throwable result)) {
		if (exists token = context.user()) {
			if (is Object userInfo = decodeUserInfo(token.principal().getString("access_token"))) {
				handler(KeycloakUserInfo(userInfo));
			} else {
				makeRestCall {
					url = "``baseUrl``/userinfo";
					token = token.principal().getString("access_token");
					void bodyHandler(Buffer|Throwable result) {
						if (is Buffer result) {
							handler(KeycloakUserInfo(result.toJsonObject()));
						} else {
							handler(result);
						}
					}
				};
			}
		} else {
			handler(Exception("No login token available"));
		}
	}
	
	shared void logout(RoutingContext context, void handler(Throwable? error)) {
		if (exists token = context.user()) {
			makeRestCall {
				url = "``baseUrl``/logout";
				token = token.principal().getString("access_token");
				void bodyHandler(Buffer|Throwable result) {
					if (is Buffer result) {
						handler(null);
					} else {
						handler(result);
					}
				}
			};
		} else {
			handler(Exception("No login token available"));
		}
	}

}