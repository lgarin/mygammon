final shared class RoomSize(shared Integer tableCount, shared Integer playerCount) extends Object() {
	
	shared actual Boolean equals(Object that) {
		if (is RoomSize that) {
			return tableCount==that.tableCount && 
				playerCount==that.playerCount;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + tableCount;
		hash = 31*hash + playerCount;
		return hash;
	}
	
	
}