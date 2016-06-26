package backgammon.vertx;

import java.net.URL;

import io.vertx.core.json.JsonObject;

public class UserInfo {

	private String displayName;
	private String pictureUrl;
	
	public UserInfo(String displayName, String pictureUrl) {
		this.displayName = displayName;
		this.pictureUrl = pictureUrl;
	}
	public String getDisplayName() {
		return displayName;
	}
	public String getPictureUrl() {
		return pictureUrl;
	}
	
	public static UserInfo parseGoogleJson(JsonObject json) {
		String displayName = json.getString("displayName");
		String pictureUrl = json.getJsonObject("image").getString("url");
		return new UserInfo(displayName, pictureUrl);
	}
}
