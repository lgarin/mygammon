
shared abstract class CheckerColor() of black | white {
	shared formal CheckerColor oppositeColor;
	shared formal String name;
	string => name;
}
shared object black extends CheckerColor() {
 	oppositeColor => white;
 	name => "black";
}
shared object white extends CheckerColor() {
	oppositeColor => black;
	name => "white";
}

shared CheckerColor player1Color = black;
shared CheckerColor player2Color = white;

shared CheckerColor parseCheckerColor(String name) {
	if (name == white.name) {
		return white;
	} else if (name == black.name) {
		return black;
	} else {
		throw Exception("Invalid color: ``name``");
	}
}