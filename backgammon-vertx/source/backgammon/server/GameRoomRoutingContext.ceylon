import backgammon.shared {
	PlayerInfo,
	MatchId,
	TableId,
	RoomId,
	PlayerId
}

import ceylon.json {
	Object
}
import ceylon.time {
	Instant
}

import io.vertx.ceylon.web {
	RoutingContext,
	cookieFactory=cookie
}

final class GameRoomRoutingContext(RoutingContext rc) {
	
	shared void setCurrentPlayerInfo(PlayerInfo playerInfo) {
		rc.session()?.put("playerInfo", playerInfo);
		rc.addCookie(cookieFactory.cookie("playerInfo", playerInfo.toBase64()));
	}
	
	shared void clearUser() {
		rc.session()?.destroy();
		rc.user()?.clearCache();
		rc.clearUser();
		rc.removeCookie("playerInfo");
		rc.removeCookie("vertx-web.session");
	}
	
	PlayerInfo? getCurrentPlayerInfo() => rc.session()?.get<PlayerInfo>("playerInfo");
	
	shared PlayerId? getCurrentPlayerId(Boolean withFailure = true) {
		if (exists playerInfo = getCurrentPlayerInfo()) {
			return PlayerId(playerInfo.id);
		} else {
			if (withFailure) {
				failWithUnauthorized();
			}
			return null;
		}
	}
	
	shared RoomId? getRequestRoomId(Boolean withFailure = true) {
		if (exists roomId = rc.request().getParam("roomId")) {
			return RoomId(roomId);
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	shared PlayerId? getRequestPlayerId(Boolean withFailure = true) {
		if (exists playerId = rc.request().getParam("playerId")) {
			return PlayerId(playerId);
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	shared TableId? getRequestTableId(Boolean withFailure = true) {
		if (exists roomId = rc.request().getParam("roomId"), exists table = rc.request().getParam("tableIndex")) {
			if (exists tableIndex = parseInteger(table)) {
				return TableId(roomId, tableIndex);
			} else {
				if (withFailure) {
					failWithBadRequest();
				}
				return null;
			}
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	shared MatchId? getRequestMatchId(Boolean withFailure = true) {
		if (exists match = rc.request().getParam("matchTimestamp"), exists tableId = getRequestTableId()) {
			if (exists matchTimestamp = parseInteger(match)) {
				return MatchId(tableId, Instant(matchTimestamp));
			} else {
				if (withFailure) {
					failWithBadRequest();
				}
				return null;
			}
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	function getRequestIntegerParameter(String name, Boolean withFailure) {
		if (exists position = rc.request().getParam(name)) {
			return parseInteger(position);
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	shared Integer? getRequestSourcePosition(Boolean withFailure = true) => getRequestIntegerParameter("sourcePosition", withFailure);
	
	shared Integer? getRequestTargetPosition(Boolean withFailure = true) => getRequestIntegerParameter("targetPosition", withFailure);
	
	shared void sendRedirect(String url) {
		if (!rc.failed()) {
			rc.response().putHeader("Location", url).setStatusCode(302).end();
		}
	}
	
	shared void writeJsonResponse(Object json) {
		if (!rc.failed()) {
			value response = json.string;
			rc.response().headers().add("Content-Length", response.size.string);
			rc.response().headers().add("Content-Type", "application/json");
			rc.response().write(response).end();
		}
	}
	
	shared void fail(Throwable error) {
		rc.fail(error);
	}
	
	shared void failWithBadRequest() {
		rc.fail(400);
	}
	
	shared void failWithUnauthorized() {
		rc.fail(401);
	}
}