import backgammon.server {

	ServerConfiguration
}
import backgammon.server.util {

	ObtainableLock
}
import backgammon.shared {

	InboundChatRoomMessage,
	OutboundChatRoomMessage,
	PlayerInfo,
	ChatPostedMessage,
	PostChatMessage,
	ChatHistoryRequestMessage,
	ChatHistoryResponseMessage
}
import ceylon.collection {

	LinkedList
}
import ceylon.time {

	Instant
}
shared final class ChatRoom(ServerConfiguration config) {
	value lock = ObtainableLock("ChatRoom");
	
	value messages = LinkedList<ChatPostedMessage>();
	
	void clearOldMessages(Instant currentTime) {
		value minTimestamp = currentTime.minus(config.chatMessageRetention);
		messages.removeWhere((e) => e.timestamp < minTimestamp);
	}
	
	function postMessage(PostChatMessage message, PlayerInfo? playerInfo) {
		value result = ChatPostedMessage(playerInfo else PlayerInfo(message.playerId.string, ""), message.roomId, message.message, message.timestamp);
		clearOldMessages(message.timestamp);
		messages.add(result);
		return result;
	}
	
	function readHistory(ChatHistoryRequestMessage message) {
		return ChatHistoryResponseMessage(message.playerId, message.roomId, messages.sequence());
	}
	
	shared OutboundChatRoomMessage processInputMessage(InboundChatRoomMessage message, PlayerInfo? playerInfo = null) {
		try (lock) {
			switch (message)
			case (is PostChatMessage) {
				return postMessage(message, playerInfo);
			}
			case (is ChatHistoryRequestMessage) {
				return readHistory(message);
			}
		}
	}
}