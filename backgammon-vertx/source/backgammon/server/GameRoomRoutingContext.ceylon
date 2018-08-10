import backgammon.shared {
	PlayerInfo,
	MatchId,
	TableId,
	RoomId,
	PlayerId
}

import ceylon.json {
	JsonObject,
	Emitter,
	visit
}
import ceylon.time {
	Instant
}

import io.vertx.ceylon.web {
	RoutingContext,
	cookieFactory=cookie
}
import io.vertx.ceylon.core.buffer {

	bufferFactory=buffer_,
	Buffer
}

final class GameRoomRoutingContext(RoutingContext rc) {
	
	shared void setCurrentPlayerInfo(PlayerInfo playerInfo) {
		if (exists session = rc.session()) {
			session.put("playerInfo", playerInfo);
			if (exists cookie = rc.getCookie("playerId")) {
				cookie.setValue(playerInfo.id);
			} else {
				rc.addCookie(cookieFactory.cookie("playerId", playerInfo.id));
			}
		}
	}
	
	shared void clearUser() {
		rc.session()?.destroy();
		rc.user()?.clearCache();
		rc.clearUser();
		if (exists cookie = rc.getCookie("playerId")) {
			cookie.setMaxAge(0);
		}
	}

	shared PlayerInfo? getCurrentPlayerInfo() => rc.session()?.get<PlayerInfo>("playerInfo");
	
	shared PlayerId? getCurrentPlayerId(Boolean withFailure = true) {
		if (exists playerInfo = getCurrentPlayerInfo()) {
			return playerInfo.playerId;
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
	
	shared Integer? getRequestIntegerParameter(String name, Boolean withFailure = true) {
		if (exists position = rc.request().getParam(name)) {
			return parseInteger(position);
		} else {
			if (withFailure) {
				failWithBadRequest();
			}
			return null;
		}
	}
	
	shared void sendRedirect(String url) {
		if (!rc.failed()) {
			rc.response().putHeader("Location", url).setStatusCode(302).end();
		}
	}
	
	final class JsonBuffer(String encoding) extends Emitter(false) {
		
		value buffer = bufferFactory.buffer(8192);
		value builder = StringBuilder();
		
		void flushToBuffer() {
			buffer.appendString(builder.string, encoding);
			builder.clear();
		}
		
		shared actual void print(String string) {
			builder.append(string);
			if (builder.longerThan(1000)) {
				flushToBuffer();
			}
		}
		
		shared Buffer encode(JsonObject json) {
			visit(json, this);
			if (!builder.empty) {
				flushToBuffer();
			}
			return buffer;
		}
	}

	shared void writeJsonResponse(JsonObject json) {
		if (!rc.failed()) {
			value response = JsonBuffer("UTF-8").encode(json);
			rc.response().headers().add("Content-Length", response.length().string);
			rc.response().headers().add("Content-Type", "application/json; charset=utf-8");
			rc.response().headers().add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
			rc.response().end(response);
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
	
	shared void failWithServiceUnavailable() {
		rc.fail(503);
	}
}