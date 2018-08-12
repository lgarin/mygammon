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
	
	value messages = LinkedList<PostChatMessage>();
	
	void clearOldMessages(Instant currentTime) {
		value minTimestamp = currentTime.minus(config.chatMessageRetention);
		messages.removeWhere((e) => e.timestamp < minTimestamp);
	}
	
	function toPostedMessage(PostChatMessage message) => ChatPostedMessage(PlayerInfo(message.playerId.string, ""), message.roomId, message.message, message.timestamp);
	
	function postMessage(PostChatMessage message) {
		clearOldMessages(message.timestamp);
		messages.add(message);
		return toPostedMessage(message);
	}
	
	function readHistory(ChatHistoryRequestMessage message) {
		return ChatHistoryResponseMessage(message.playerId, message.roomId, messages.map(toPostedMessage).sequence());
	}
	
	shared OutboundChatRoomMessage processInputMessage(InboundChatRoomMessage message) {
		try (lock) {
			switch (message)
			case (is PostChatMessage) {
				return postMessage(message);
			}
			case (is ChatHistoryRequestMessage) {
				return readHistory(message);
			}
		}
	}
}