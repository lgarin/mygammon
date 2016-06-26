package backgammon.vertx;

import io.vertx.core.Handler;
import io.vertx.core.http.HttpClient;
import io.vertx.core.http.HttpClientRequest;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.RoutingContext;

public class GoogleProfileClient {

	private final HttpClient httpClient;
	
	public GoogleProfileClient(HttpClient httpClient) {
		this.httpClient = httpClient;
	}
	
	public void fetchUserInfo(RoutingContext context, Handler<UserInfo> handler) {
		HttpClientRequest request = httpClient.getAbs("https://www.googleapis.com/plus/v1/people/me?fields=displayName%2Cimage%2Furl&key=AIzaSyBCs5hbaFFCdz2fs8hc53s7XRLJXwhIq-4");
		if (context.user() == null) {
			handler.handle(null);
		}
		
		request.headers().add("Authorization", "Bearer " + context.user().principal().getString("access_token"));
		request.handler(res -> {
			if (res.statusCode() == 200) {
				res.bodyHandler(body ->  {
					JsonObject json = body.toJsonObject();
					handler.handle(UserInfo.parseGoogleJson(json));
				});
			} else {
				handler.handle(null);
			}
		});
		request.end();
	}
}
