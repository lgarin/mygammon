import backgammon.common {
	PlayerInfo,
	MatchId,
	TableId,
	RoomId,
	PlayerId
}

import ceylon.time {
	Instant
}

import io.vertx.ceylon.web {
	RoutingContext,
	cookieFactory=cookie
}
import ceylon.json {

	Object
}

final class GameRoomRoutingContext(RoutingContext rc) {
	
	shared void setCurrentPlayerInfo(PlayerInfo playerInfo) {
		rc.session()?.put("playerInfo", playerInfo);
		rc.addCookie(cookieFactory.cookie("playerInfo", playerInfo.toBase64()));
	}
	
	shared PlayerInfo? getCurrentPlayerInfo() => rc.session()?.get<PlayerInfo>("playerInfo");
	
	shared PlayerId? getCurrentPlayerId() {
		if (exists playerInfo = getCurrentPlayerInfo()) {
			return PlayerId(playerInfo.id);
		} else {
			return null;
		}
	}
	
	shared RoomId? getRequestRoomId() {
		if (exists roomId = rc.request().getParam("roomId")) {
			return RoomId(roomId);
		} else {
			return null;
		}
	}
	
	shared TableId? getRequestTableId() {
		if (exists roomId = rc.request().getParam("roomId"), exists table = rc.request().getParam("tableIndex")) {
			if (exists tableIndex = parseInteger(table)) {
				return TableId(roomId, tableIndex);
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	shared MatchId? getRequestMatchId() {
		if (exists match = rc.request().getParam("matchTimestamp"), exists tableId = getRequestTableId()) {
			if (exists matchTimestamp = parseInteger(match)) {
				return MatchId(tableId, Instant(matchTimestamp));
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	shared void sendRedirect(String url) {
		rc.response().putHeader("Location", url).setStatusCode(302).end();
	}
	
	shared void writeJsonResponse(Object json) {
		value response = json.string;
		rc.response().headers().add("Content-Length", response.size.string);
		rc.response().headers().add("Content-Type", "application/json");
		rc.response().write(response).end();
	}
}