import ceylon.collection {
	HashMap,
	linked
}
import ceylon.time {

	Duration
}
import ceylon.time.base {

	milliseconds
}
import ceylon.test {

	test
}

shared object world {
	value roomMap = HashMap<RoomId, Room>(linked);
	
	shared Duration maximumGameJoinTime = Duration(30 * milliseconds.perSecond);
	shared Duration maximumTurnTime = Duration(60 * milliseconds.perSecond);
	
	shared variable Anything(TableMessage)? messageListener = null;
	
	shared void publish(TableMessage message) {
		if (exists listener = messageListener) {
			listener(message);
		}
	}
	
	shared Collection<RoomId> rooms => roomMap.keys;

	shared RoomId? createRoom(String id, Integer tableCount) {
		if (roomMap.defines(RoomId(id))) {
			return null;
		}
		value room = Room(id, tableCount);
		roomMap.put(room.id, room);
		return room.id;
	}
	
	shared PlayerId? createPlayer(RoomId roomId, String name) {
		if (exists room = roomMap[roomId]) {
			return room.createPlayer(name).id;
		} else {
			return null;
		}
	}
	
	// TODO add all methods for Player class
}

class WorldTest() {
	test
	shared void createRoomAddsNewRoom() {
		value roomId = "test1";
		value r = world.createRoom(roomId, 10);
		assert (exists r);
		assert (r.string == roomId);
		assert (world.rooms.contains(r));
	}

	test
	shared void cannotCreateTwoRoomsWithSameId() {
		value roomId = "test2";
		value r1 = world.createRoom(roomId, 10);
		assert (exists r1);
		value r2 = world.createRoom(roomId, 20);
		assert (r2 is Null);
		assert (world.rooms.contains(r1));
	}
}

