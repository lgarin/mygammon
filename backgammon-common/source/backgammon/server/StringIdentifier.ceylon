shared abstract class StringIdentifier(String id) satisfies Identifiable {
	string = id;
	
	shared actual Boolean equals(Object that) {
		return id == that.string;
	}
	
	shared actual Integer hash => id.hash;
}