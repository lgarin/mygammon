import backgammon.shared {

	ChatPostedMessage,
	InboundChatRoomMessage,
	OutboundChatRoomMessage,
	ChatHistoryResponseMessage,
	PostChatMessage,
	PlayerId,
	RoomId,
	ChatHistoryRequestMessage,
	ChatMissedResponseMessage
}
import backgammon.client {

	TableGui
}
import ceylon.collection {

	naturalOrderTreeMap,
	TreeMap
}
import ceylon.json {

	JsonArray,
	JsonObject
}
shared final class ChatClient(PlayerId playerId, RoomId roomId, TableGui gui, Anything(Integer) lastMessageIdWriter, Anything(InboundChatRoomMessage) chatCommander) {

	variable TreeMap<Integer, ChatPostedMessage>? chatModel = null;
	
	variable Integer unreadMessageCount = 0;
	
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
			} else {
				unreadMessageCount = 0;
				gui.showChatIcon(unreadMessageCount);
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
			if (exists model = chatModel, !model.defines(message.messageId)) {
				model.put(message.messageId, message);
				if (model.size == 1) {
					displayMessages({message});
				} else {
					gui.appendChatMessage(JsonObject(toTemplateData(message)));
				}
				if (gui.isDropDownVisible("chat-dropdown")) {
					lastMessageIdWriter(message.messageId);
				} else {
					gui.showChatIcon(++unreadMessageCount);
				}
			} else if (!chatModel exists) {
				gui.showChatIcon(++unreadMessageCount);
			}
			return true;
		}
		case (is ChatHistoryResponseMessage) {
			chatModel = naturalOrderTreeMap {for (entry in message.history) entry.messageId -> entry};
			displayMessages(message.history);
			lastMessageIdWriter(message.history.last?.messageId else 0);
			unreadMessageCount = 0;
			gui.showChatIcon(unreadMessageCount);
			return true;
		}
		case (is ChatMissedResponseMessage) {
			unreadMessageCount = message.newMessageCount;
			gui.showChatIcon(unreadMessageCount);
			return true;
		}
	}
}