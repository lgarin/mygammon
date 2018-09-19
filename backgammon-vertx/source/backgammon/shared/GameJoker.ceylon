
shared abstract class GameJoker() of takeTurnJoker | controlRollJoker | undoTurnJoker | replayTurnJoker {
	shared formal String name;
	string => name;
}

shared object takeTurnJoker extends GameJoker() {
	name => "takeTurn";
}

shared object controlRollJoker extends GameJoker() {
	name => "controlRoll";
}

shared object undoTurnJoker extends GameJoker() {
	name => "undoTurn";
}

shared object replayTurnJoker extends GameJoker() {
	name => "replayTurn";
}

shared GameJoker parseGameJoker(String name) {
	if (name == takeTurnJoker.name) {
		return takeTurnJoker;
	} else if (name == controlRollJoker.name) {
		return controlRollJoker;
	} else if (name == undoTurnJoker.name) {
		return undoTurnJoker;
	} else if (name == replayTurnJoker.name) {
		return replayTurnJoker;
	} else {
		throw Exception("Invalid joker: ``name``");
	}
}

shared GameJoker? parseNullableGameJoker(String? name) => if (exists name) then parseGameJoker(name) else null; 
