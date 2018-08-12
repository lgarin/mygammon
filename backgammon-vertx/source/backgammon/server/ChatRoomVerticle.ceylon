import backgammon.server.bus {
	ChatRoomEventBus,
	PlayerRosterEventBus
}
import backgammon.server.chat {
	ChatRoom
}
import backgammon.server.room {
	RoomConfiguration
}
import backgammon.shared {
	OutboundChatRoomMessage,
	InboundChatRoomMessage,
	ChatPostedMessage,
	PlayerInfoRequestMessage,
	PlayerInfoOutputMessage
}

import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Future,
	Verticle
}

final class ChatRoomVerticle()  extends Verticle() {
	
	value log = logger(`package`);
	
	shared actual void startAsync(Future<Anything> startFuture) {
		value serverConfig = ServerConfiguration(config);
		value chatEventBus = ChatRoomEventBus(vertx, serverConfig);
		value rosterEventBus = PlayerRosterEventBus(vertx, serverConfig);
		value chatRoom = ChatRoom(serverConfig);
		
		void processInputMessage(InboundChatRoomMessage message, Anything(OutboundChatRoomMessage|Throwable) callback) {
			
			void publishAndCallback(OutboundChatRoomMessage|Throwable result) {
				if (is ChatPostedMessage result) {
					chatEventBus.publishOutboundMessage(result);
				}
				callback(result);
			}
			
			value output = chatRoom.processInputMessage(message);
			if (nonempty playerIds = output.playerIds) {
				void playerInfoContinuation(PlayerInfoOutputMessage|Throwable result) {
					if (is Throwable result) {
						publishAndCallback(result);
					} else {
						publishAndCallback(output.withPlayerInfos(result));
					}
				}
				rosterEventBus.sendInboundMessage(PlayerInfoRequestMessage(playerIds.first, playerIds.rest, message.timestamp), playerInfoContinuation);
			} else {
				publishAndCallback(output);
			}
		}
		
		chatEventBus.disableOutput = true;
		log.info("Starting chat ``serverConfig.roomId``...");
		chatEventBus.replayAllEvents(serverConfig.roomId, chatRoom.processInputMessage, (result) {
			if (is Throwable result) {
				startFuture.fail(result);
			} else {
				chatEventBus.registerAsyncConsumer(serverConfig.roomId, processInputMessage);
				
				chatEventBus.disableOutput = false;
				log.info("Chat room ``serverConfig.roomId`` events : ``result``");
				startFuture.complete();
			}
		});
	}
	
	shared actual void stop() {
		value roomConfig = RoomConfiguration(config);
		log.info("Stopped chat : ``roomConfig.roomId``");
	}
}