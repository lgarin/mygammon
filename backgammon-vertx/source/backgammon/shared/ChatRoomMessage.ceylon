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

shared sealed interface InboundChatRoomMessage of PostChatMessage | ChatHistoryRequestMessage | ChatMissedRequestMessage satisfies ChatRoomMessage {
	shared formal Instant timestamp;
}

shared sealed interface OutboundChatRoomMessage of ChatPostedMessage | ChatHistoryResponseMessage | ChatMissedResponseMessage satisfies ChatRoomMessage {
	shared default [PlayerId*] playerIds => [playerId];
	shared formal OutboundChatRoomMessage withPlayerInfos(Correspondence<PlayerId, PlayerInfo> result);
}

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

shared final class ChatMissedRequestMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer lastMessageId, shared actual Instant timestamp = now()) satisfies InboundChatRoomMessage {
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "lastMessageId" -> lastMessageId, "timestamp" -> timestamp.millisecondsOfEpoch };
	mutation => false;
}
ChatMissedRequestMessage parseChatMissedRequestMessage(Object json) {
	return ChatMissedRequestMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getInteger("lastMessageId"), Instant(json.getInteger("timestamp")));
}

shared final class ChatPostedMessage(shared PlayerInfo playerInfo, shared actual RoomId roomId, shared Integer messageId, shared String message, shared Instant timestamp) satisfies OutboundChatRoomMessage {
	playerId = playerInfo.playerId;
	toJson() => Object{ "playerInfo" -> playerInfo.toJson(), "roomId" -> roomId.toJson(), "messageId" -> messageId, "message" -> message, "timestamp" -> timestamp.millisecondsOfEpoch };
	withPlayerInfos(Correspondence<PlayerId,PlayerInfo> result) => ChatPostedMessage(result[playerId] else playerInfo, roomId, messageId, message, timestamp);
	
}
ChatPostedMessage parseChatPostedMessage(Object json) {
	return ChatPostedMessage(parsePlayerInfo(json.getObject("playerInfo")), parseRoomId(json.getString("roomId")), json.getInteger("messageId"), json.getString("message"), Instant(json.getInteger("timestamp")));
}

shared final class ChatHistoryResponseMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared [ChatPostedMessage*] history) satisfies OutboundChatRoomMessage {
	playerIds => set(history*.playerId).sequence();
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "history" ->  JsonArray(history*.toJson()) };
	withPlayerInfos(Correspondence<PlayerId,PlayerInfo> result) => ChatHistoryResponseMessage(playerId, roomId, history*.withPlayerInfos(result).narrow<ChatPostedMessage>().sequence());
}
ChatHistoryResponseMessage parseChatHistoryResponseMessage(Object json) {
	return ChatHistoryResponseMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getArray("history").narrow<Object>().collect(parseChatPostedMessage) );
}

shared final class ChatMissedResponseMessage(shared actual PlayerId playerId, shared actual RoomId roomId, shared Integer newMessageCount) satisfies OutboundChatRoomMessage {
	playerIds => [];
	toJson() => Object{ "playerId" -> playerId.toJson(), "roomId" -> roomId.toJson(), "newMessageCount" -> newMessageCount };
	withPlayerInfos(Correspondence<PlayerId,PlayerInfo> result) => this;
}
ChatMissedResponseMessage parseChatMissedResponseMessage(Object json) {
	return ChatMissedResponseMessage(parsePlayerId(json.getString("playerId")), parseRoomId(json.getString("roomId")), json.getInteger("newMessageCount"));
}