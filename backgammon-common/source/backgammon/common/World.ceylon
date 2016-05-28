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
	value roomMap = HashMap<String, RoomImpl>(linked);
	
	shared Duration maximumGameJoinTime = Duration(30 * milliseconds.perSecond);
	
	shared Map<String, Room> rooms => roomMap;

	shared Room createRoom(String id, Integer tableCount) {
		value room = RoomImpl(id, tableCount);
		roomMap.put(room.id, room);
		return room;
	}
	
	shared Game createDetachedGame(String player1, String player2, Anything(PlayerMessage) messageListener) {
		value table = TableImpl(0);
		return GameImpl(PlayerImpl(player1, messageListener), PlayerImpl(player2, messageListener), table);
	}
}

class WorldTest() {
	test
	shared void createRoomAddsNewRoom() {
		String roomId = "test1";
		Room r = world.createRoom(roomId, 10);
		assert (r.id == roomId);
		assert (exists it = world.rooms[roomId]);
	}
	
	test
	shared void createRoomReplaceExistingRoom() {
		String roomId = "test1";
		world.createRoom(roomId, 10);
		world.createRoom(roomId, 20);
		assert (world.rooms.size == 1);
		assert (exists it = world.rooms[roomId]);
		assert (it.tables.size == 20);
	}
}

