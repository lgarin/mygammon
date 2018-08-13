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
	ChatHistoryResponseMessage,
	ChatMissedResponseMessage,
	ChatMissedRequestMessage
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
	
	function toPostedMessage(PostChatMessage message, Integer messageId) {
		 return ChatPostedMessage(
		 	PlayerInfo(message.playerId.string),
		 	message.roomId,
		 	messageId,
		 	message.message, 
		 	message.timestamp);
	}
	
	function postMessage(PostChatMessage message) {
		clearOldMessages(message.timestamp);
		value result = toPostedMessage(message, messages.size + 1);
		messages.add(result);
		return result;
	}
	
	function readHistory(ChatHistoryRequestMessage message) {
		return ChatHistoryResponseMessage(message.playerId, message.roomId, messages.sequence());
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
			case (is ChatMissedRequestMessage) {
				return ChatMissedResponseMessage(message.playerId, message.roomId, messages.size - message.lastMessageId);
			}
		}
	}
}