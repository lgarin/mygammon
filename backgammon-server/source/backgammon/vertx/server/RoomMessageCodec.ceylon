import backgammon.common {
	RoomMessage,
	EnterRoomMessage,
	parseEnterRoomMessage
}

import ceylon.json {
	Object,
	parse
}

import io.vertx.core.buffer {
	Buffer
}
import io.vertx.core.eventbus {
	MessageCodec
}

// not used because vertx for ceylon does not support message codec 
interface RoomMessageCodec<Message> satisfies MessageCodec<Message, Message> given Message satisfies RoomMessage {
	
	shared formal Message parseJson(Object json);
	
	shared actual Message decodeFromWire(Integer position, Buffer? buffer) {
		assert (exists buffer);
		value length = buffer.getInt(position);
		value string = buffer.getString(position + 4, length);
		value json = parse(string);
		assert (is Object json);
		return parseJson(json);
	}
	
	shared actual void encodeToWire(Buffer? buffer, Message? message) {
		assert (exists message, exists buffer);
		value string = message.toJson().string;
		buffer.appendInt(string.size);
		buffer.appendString(string);
	}
	
	shared actual String name() => `Message`.string;
	
	shared actual Byte systemCodecID() => Byte(-1);
	
	shared actual Message transform(Message? message) {
		assert (exists message);
		return message;
	}
}

class EnterRoomMessageCodec() satisfies RoomMessageCodec<EnterRoomMessage> {
	parseJson = parseEnterRoomMessage;
}