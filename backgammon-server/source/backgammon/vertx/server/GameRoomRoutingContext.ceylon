import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.web {

	RoutingContext,
	cookieFactory=cookie
}
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

// TODO rename to GameRoomRoutingContext
class HttpGameRoom() {
	
	shared void setCurrentPlayerInfo(RoutingContext rc, PlayerInfo playerInfo) {
		rc.session()?.put("playerInfo", playerInfo);
		rc.addCookie(cookieFactory.cookie("playerInfo", playerInfo.toBase64()));
	}
	
	shared PlayerInfo? getCurrentPlayerInfo(RoutingContext rc) => rc.session()?.get<PlayerInfo>("playerInfo");
	
	shared PlayerId? getCurrentPlayerId(RoutingContext rc) {
		if (exists playerInfo = getCurrentPlayerInfo(rc)) {
			return PlayerId(playerInfo.id);
		} else {
			return null;
		}
	}
	
	shared RoomId? getRequestRoomId(RoutingContext rc) {
		if (exists roomId = rc.request().getParam("roomId")) {
			return RoomId(roomId);
		} else {
			return null;
		}
	}
	
	shared TableId? getRequestTableId(RoutingContext rc) {
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
	
	shared MatchId? getRequestMatchId(RoutingContext rc) {
		if (exists match = rc.request().getParam("matchTimestamp"), exists tableId = getRequestTableId(rc)) {
			if (exists matchTimestamp = parseInteger(match)) {
				return MatchId(tableId, Instant(matchTimestamp));
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
}