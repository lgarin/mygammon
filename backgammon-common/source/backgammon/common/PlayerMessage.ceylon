shared sealed interface PlayerMessage of InboundPlayerMessage | TableMessage {
	shared formal PlayerId playerId;
}

shared sealed interface InboundPlayerMessage of EnterRoomMessage | LeaveRoomMessage satisfies PlayerMessage {}

shared final class EnterRoomMessage(shared actual PlayerId playerId, RoomId roomId) satisfies InboundPlayerMessage {}
shared final class LeaveRoomMessage(shared actual PlayerId playerId, RoomId roomId) satisfies InboundPlayerMessage {}