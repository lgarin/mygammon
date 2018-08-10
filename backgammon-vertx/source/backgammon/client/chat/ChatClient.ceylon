import backgammon.shared {

	ChatPostedMessage,
	InboundChatRoomMessage,
	OutboundChatRoomMessage,
	ChatHistoryResponseMessage,
	PostChatMessage,
	PlayerId,
	RoomId,
	ChatHistoryRequestMessage
}
import backgammon.client {

	TableGui
}
import ceylon.time {

	Instant
}
import ceylon.collection {

	naturalOrderTreeMap,
	TreeMap
}
import ceylon.json {

	JsonArray,
	JsonObject
}
shared final class ChatClient(PlayerId playerId, RoomId roomId, TableGui gui, Anything(InboundChatRoomMessage) chatCommander) {
	
	final class ChatKey(shared Instant timestamp, shared PlayerId playerId) satisfies Comparable<ChatKey> {
		shared actual Comparison compare(ChatKey other) {
			value c1 = timestamp.compare(other.timestamp);
			if (c1 == equal) {
				return playerId.id.compare(other.playerId.id);
			}
			return c1;
		}
	}
	
	variable TreeMap<ChatKey, ChatPostedMessage>? chatModel = null;
	
	shared Boolean postMessage() {
		value message = gui.readElementValue(gui.chatInputFieldId);
		if (exists message, !message.empty) {
			chatCommander(PostChatMessage(playerId, roomId, message));
			gui.writeElementValue(gui.chatInputFieldId, "");
			return true;
		}
		return false;
	}
	
	shared Boolean toggleHistory() {
		if (gui.toggleDropDown("chat-dropdown")) {
			if (!chatModel exists) {
				chatCommander(ChatHistoryRequestMessage(playerId, roomId));
			}
		}
		return true;
	}
	
	function toTemplateData(ChatPostedMessage item) {
		value playerLevel = item.playerInfo.level exists then "player-level level-``item.playerInfo.level else 0``" else "";
		return {"player-name" -> item.playerInfo.name, "player-level" -> playerLevel, "message-time" -> item.timestamp.dateTime().string, "message-text" -> item.message };
	}
	
	void displayMessages({ChatPostedMessage*} messages) {
		value data = JsonArray { for (item in messages) JsonObject(toTemplateData(item)) };
		gui.showChatMessages(data);
	}
	
	shared Boolean handleChatMessage(OutboundChatRoomMessage message) {
		switch (message)
		case (is ChatPostedMessage) {
			value key = ChatKey(message.timestamp, message.playerId);
			if (exists model = chatModel, !model.contains(key)) {
				model.put(key, message);
				displayMessages(model.items);
			}
			return true;
		}
		case (is ChatHistoryResponseMessage) {
			chatModel = naturalOrderTreeMap {for (entry in message.history) ChatKey(entry.timestamp, entry.playerId) -> entry};
			displayMessages(chatModel?.items else {});
			return true;
		}
	}
}