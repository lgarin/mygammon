import ceylon.time {

	Instant,
	now
}
import ceylon.json {

	Object,
	JsonArray=Array
}
shared sealed interface ChatRoomMessage of InboundChatRoomMessage | OutboundChatRoomMessage satisfies ApplicationMessage {
	shared formal PlayerId playerId;
	shared formal RoomId roomId;
}

shared sealed interface InboundChatRoomMessage of PostChatMessage | ChatHistoryRequestMessage satisfies ChatRoomMessage {
	shared formal Instant timestamp;
}

shared sealed interface OutboundChatRoomMessage of ChatPostedMessage | ChatHistoryResponseMessage satisfies ChatRoomMessage {}

shared final class PostChatMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared String message, shared actual Instant timestamp = now()) satisfies InboundChatRoomMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "message" -> message, "timestamp" -> timestamp.millisecondsOfEpoch };
}
PostChatMessage parsePostChatMessage(Object json) {
	return PostChatMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getString("message"), Instant(json.getInteger("timestamp")));
}

shared final class ChatHistoryRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared actual Instant timestamp = now()) satisfies InboundChatRoomMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
ChatHistoryRequestMessage parseChatHistoryRequestMessage(Object json) {
	return ChatHistoryRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), Instant(json.getInteger("timestamp")));
}

shared final class ChatPostedMessage(shared PlayerInfo playerInfo, shared actual RoomId roomId, shared String message, shared Instant timestamp) satisfies OutboundChatRoomMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "roomId" -> roomId.toJson(), "message" -> message, "timestamp" -> timestamp.millisecondsOfEpoch };
}
ChatPostedMessage parseChatPostedMessage(Object json) {
	return ChatPostedMessage(parsePlayerInfo(json.getObject("playerInfo")), parseRoomId(json.getString("roomId")), json.getString("message"), Instant(json.getInteger("timestamp")));
}

shared final class ChatHistoryResponseMessage(shared actual PlayerId playerId, shared actual RoomId roomId, [ChatPostedMessage*] history) satisfies OutboundChatRoomMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "history" ->  JsonArray(history*.toJson()) };
}
ChatHistoryResponseMessage parseChatHistoryResponseMessage(Object json) {
	return ChatHistoryResponseMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getArray("history").narrow<Object>().collect(parseChatPostedMessage) );
}