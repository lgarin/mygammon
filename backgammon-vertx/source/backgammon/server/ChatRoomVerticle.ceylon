import io.vertx.ceylon.core {

	Future,
	Verticle
}
import ceylon.logging {

	logger
}
import backgammon.server.room {

	RoomConfiguration
}
import backgammon.server.chat {

	ChatRoom
}
import backgammon.server.bus {

	ChatRoomEventBus,
	PlayerRosterEventBus
}
import backgammon.shared {

	OutboundChatRoomMessage,
	InboundChatRoomMessage,
	PlayerStatisticRequestMessage,
	PlayerStatisticOutputMessage,
	PostChatMessage,
	ChatPostedMessage
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
			
			void playerInfoContinuation(PlayerStatisticOutputMessage|Throwable result) {
				if (is Throwable result) {
					publishAndCallback(result);
				} else {
					log.info("Found ``result.playerInfo.toJson()``");
					publishAndCallback(chatRoom.processInputMessage(message, result.playerInfo));
				}
			}

			if (message is PostChatMessage) {
				log.info("Replay ``message.toJson()``");
				rosterEventBus.sendInboundMessage(PlayerStatisticRequestMessage(message.playerId, message.timestamp), playerInfoContinuation);
			} else {
				publishAndCallback(chatRoom.processInputMessage(message));
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